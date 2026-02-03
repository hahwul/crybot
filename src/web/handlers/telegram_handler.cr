require "json"
require "../../session/manager"

module Crybot
  module Web
    module Handlers
      class TelegramHandler
        def initialize(@sessions : Session::Manager)
        end

        # GET /api/telegram/conversations - List all telegram conversations
        def list_conversations(env) : String
          all_sessions = @sessions.list_sessions

          # Filter for telegram sessions (prefix "telegram_")
          telegram_sessions = all_sessions.select(&.starts_with?("telegram_"))

          conversations = telegram_sessions.map do |session_id|
            messages = @sessions.get_or_create(session_id)
            last_message = messages.last?

            {
              id:      session_id,
              title:   extract_title(session_id),
              preview: last_message.try { |m| m.content.try(&.[0...50]) } || "No messages",
              time:    last_message ? format_time(last_message) : "",
            }
          end

          # Sort by time (most recent first) - using session ID as proxy for now
          conversations = conversations.reverse

          {
            conversations: conversations,
            count:         conversations.size,
          }.to_json
        rescue e : Exception
          env.response.status_code = 500
          {error: e.message}.to_json
        end

        # GET /api/telegram/conversations/:id - Get conversation messages
        def get_conversation(env) : String
          session_id = env.params.url["id"]

          # Ensure it's a telegram session
          unless session_id.starts_with?("telegram_")
            env.response.status_code = 400
            return {error: "Not a telegram conversation"}.to_json
          end

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
        rescue e : Exception
          env.response.status_code = 500
          {error: e.message}.to_json
        end

        # POST /api/telegram/conversations/:id/message - Send message to telegram conversation
        def send_message(env) : String
          session_id = env.params.url["id"]
          body = env.request.body.try(&.gets_to_end) || ""
          data = JSON.parse(body)

          content = data["content"]?.try(&.as_s) || ""

          if content.empty?
            env.response.status_code = 400
            return {error: "Message content is required"}.to_json
          end

          # This would need to be handled by the agent/loop
          # For now, return an error indicating this isn't fully implemented
          {
            error: "Sending to telegram conversations not yet implemented",
            note:  "Use the actual telegram interface for now",
          }.to_json
        end

        private def extract_title(session_id : String) : String
          # Extract user ID from session_id (format: telegram_<user_id>)
          if session_id =~ /^telegram_(.+)$/
            user_id = $1
            # Try to make it more readable
            if user_id.includes?("_")
              parts = user_id.split("_")
              if parts.size >= 2
                # Format: telegram_<username>_<chat_id> or similar
                username = parts[0]
                return username == "unknown" ? "Telegram Chat" : username.capitalize
              end
            end
            return "Telegram #{user_id[0...8]}"
          end
          "Unknown Chat"
        end

        private def format_time(message : Providers::Message) : String
          # For now, just return a placeholder
          # In a real implementation, messages would have timestamps
          "Recently"
        end
      end
    end
  end
end
