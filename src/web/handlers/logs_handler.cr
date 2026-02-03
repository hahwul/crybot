require "json"

module Crybot
  module Web
    module Handlers
      class LogsHandler
        # In-memory log storage for web UI
        @@logs = [] of Hash(String, String)
        @@max_logs = 500

        def self.log(level : String, message : String)
          @@logs << {
            "timestamp" => Time.local.to_s("%Y-%m-%dT%H:%M:%S%"),
            "level"     => level,
            "message"   => message,
          }

          # Keep only the most recent logs
          while @@logs.size > @@max_logs
            @@logs.shift
          end
        end

        # GET /api/logs - Get recent logs
        def get_logs(env) : String
          limit = env.params.query["limit"]?.try(&.to_i?) || 100

          {
            logs:  @@logs.last(limit),
            count: @@logs.size,
          }.to_json
        rescue e : Exception
          env.response.status_code = 500
          {error: e.message}.to_json
        end

        # GET /api/logs/stream - Server-sent events for real-time logs
        def stream_logs(env)
          env.response.headers["Content-Type"] = "text/event-stream"
          env.response.headers["Cache-Control"] = "no-cache"
          env.response.headers["Connection"] = "keep-alive"

          # Send initial logs
          @@logs.each do |log|
            env.response << "data: #{log.to_json}\n\n"
          end

          # For a real implementation, we'd use a channel/broadcast
          # For now, just send a keepalive every 30 seconds
          spawn do
            loop do
              sleep 30
              begin
                env.response << ":keepalive\n\n"
              rescue
                break
              end
            end
          end
        end
      end
    end
  end
end
