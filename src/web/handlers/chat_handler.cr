require "json"
require "random/secure"
require "../../agent/loop"
require "../../session/manager"

module Crybot
  module Web
    module Handlers
      class ChatHandler
        def initialize(@agent : Agent::Loop, @sessions : Session::Manager)
        end

        # POST /api/chat - Send message and get response (REST endpoint)
        def handle_message(env) : String
          body = env.request.body.try(&.gets_to_end) || ""
          data = JSON.parse(body)

          session_id = data["session_id"]?.try(&.as_s) || generate_session_key
          content = data["content"]?.try(&.as_s) || ""

          if content.empty?
            env.response.status_code = 400
            return {error: "Message content is required"}.to_json
          end

          # Process with agent
          response = @agent.process(session_id, content)

          {
            session_id: session_id,
            content:    response,
            timestamp:  Time.local.to_s("%Y-%m-%dT%H:%M:%S%:z"),
          }.to_json
        rescue e : JSON::ParseException
          env.response.status_code = 400
          {error: "Invalid JSON"}.to_json
        rescue e : Exception
          env.response.status_code = 500
          {error: e.message}.to_json
        end

        private def generate_session_key : String
          "web_#{Random::Secure.hex(16)}"
        end
      end
    end
  end
end
