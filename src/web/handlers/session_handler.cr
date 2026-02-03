require "json"
require "../../session/manager"

module Crybot
  module Web
    module Handlers
      class SessionHandler
        def initialize(@sessions : Session::Manager)
        end

        # GET /api/sessions - List all sessions
        def list_sessions(env) : String
          sessions = @sessions.list_sessions
          {
            sessions: sessions,
            count:    sessions.size,
          }.to_json
        end

        # GET /api/sessions/:id - Get session messages
        def get_session(env) : String
          session_id = env.params.url["id"]
          messages = @sessions.get_or_create(session_id)

          {
            session_id: session_id,
            messages:   messages.map do |msg|
              {
                role:    msg.role,
                content: msg.content,
              }
            end,
          }.to_json
        end

        # DELETE /api/sessions/:id - Delete session
        def delete_session(env) : String
          session_id = env.params.url["id"]
          @sessions.delete(session_id)
          env.response.status_code = 200
          {success: true}.to_json
        end
      end
    end
  end
end
