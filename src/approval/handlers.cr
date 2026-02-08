require "kemal"
require "./request"
require "./bubblejail"

module Crybot
  module Approval
    class WebHandlers
      def self.register
        # Serve the approval UI page
        get "/approval" do |env|
          pending = Request.all_pending
          render_html(pending)
        end

        # Get pending requests as JSON
        get "/api/approval/requests" do |env|
          pending = Request.all_pending
          env.response.content_type = "application/json"
          pending.map(&.to_json).to_json
        end

        # Approve a request
        post "/api/approval/:id/approve" do |env|
          id = env.params.url["id"]
          request = Request.load(id)

          if request.nil?
            env.response.status_code = 404
            next {error: "Request not found"}.to_json
          end

          # Create actual bind mount using bindfs
          mounter = BindMounter.new

          if mounter.add_mount(request.path)
            mount_point = mounter.mount_point(request.path)

            # Update request status
            request.status = "approved"
            request.save

            {
              success:     true,
              message:     "Access granted to #{request.path}",
              mount_point: mount_point,
              immediate:   true,
            }.to_json
          else
            env.response.status_code = 500
            next {error: "Failed to create bind mount"}.to_json
          end
        end

        # Deny a request
        post "/api/approval/:id/deny" do |env|
          id = env.params.url["id"]
          request = Request.load(id)

          if request.nil?
            env.response.status_code = 404
            next {error: "Request not found"}.to_json
          end

          request.status = "denied"
          request.save

          {success: true, message: "Access denied"}.to_json
        end
      end

      private def self.render_html(pending_requests : Array(Request)) : String
        <<-HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Access Approval - Crybot</title>
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@1/css/pico.min.css">
            <style>
                body { padding-top: 2rem; }
                .request-card {
                    border: 1px solid var(--muted-border-color);
                    border-radius: var(--border-radius);
                    padding: 1.5rem;
                    margin-bottom: 1rem;
                }
                .request-path {
                    font-family: monospace;
                    background: var(--code-background-color);
                    padding: 0.5rem;
                    border-radius: var(--border-radius);
                    margin: 1rem 0;
                }
                .buttons {
                    display: flex;
                    gap: 0.5rem;
                    margin-top: 1rem;
                }
                .empty-state {
                    text-align: center;
                    color: var(--muted-color);
                    padding: 3rem;
                }
                #requests { margin-top: 2rem; }
            </style>
        </head>
        <body>
            <main class="container">
                <h1>Directory Access Requests</h1>
                <p>The AI agent is requesting access to directories outside its sandbox.</p>

                <div id="requests">
                    #{render_requests(pending_requests)}
                </div>
            </main>

            <script>
                function approve(id) {
                    fetch(`/api/approval/${id}/approve`, { method: 'POST' })
                        .then(r => r.json())
                        .then(data => {
                            if (data.success) {
                                alert('Access granted!\\n\\nMount point: ' + data.mount_point + '\\n\\nThe agent can now access this directory immediately.');
                                location.reload();
                            } else {
                                alert('Error: ' + data.error);
                            }
                        });
                }

                function deny(id) {
                    if (confirm('Deny this request?')) {
                        fetch(`/api/approval/${id}/deny`, { method: 'POST' })
                            .then(r => r.json())
                            .then(data => {
                                if (data.success) {
                                    location.reload();
                                }
                            });
                    }
                }

                // Auto-refresh every 5 seconds
                setInterval(() => location.reload(), 5000);
            </script>
        </body>
        </html>
        HTML
      end

      private def self.render_requests(requests : Array(Request)) : String
        return "<div class='empty-state'>No pending requests</div>" if requests.empty?

        requests.map do |req|
          <<-HTML
          <div class="request-card" id="request-#{req.id}">
              <h3>Access Request</h3>
              <p><strong>Path:</strong></p>
              <div class="request-path">#{req.path}</div>
              <p><strong>Requested:</strong> #{req.created_at}</p>
              <div class="buttons">
                  <button onclick="approve('#{req.id}')" class="secondary">Approve</button>
                  <button onclick="deny('#{req.id}')" class="contrast">Deny</button>
              </div>
          </div>
          HTML
        end.join("\n")
      end
    end
  end
end
