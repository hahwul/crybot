require "./channel"
require "../session/manager"

module Crybot
  module Channels
    # Web channel - handles web UI chat sessions
    # Note: This is a simplified version for the unified architecture
    # The actual web server handles HTTP/WebSocket, but this provides
    # a channel interface for sending messages to web sessions
    class WebChannel < Channel
      @sessions : Session::Manager

      def initialize
        @sessions = Session::Manager.instance
      end

      def name : String
        "web"
      end

      def start : Nil
        # Web server is started separately by the web feature
        # This is a no-op for the channel adapter
      end

      def stop : Nil
        # Web server is stopped separately
      end

      def send_message(message : ChannelMessage) : Nil
        # For web, we save the message to the session
        # The web UI will pick it up via polling or WebSocket
        session_key = session_key(message.chat_id)
        messages = @sessions.get_or_create(session_key)

        # Add assistant message
        assistant_msg = Providers::Message.new(
          role: "assistant",
          content: message.content,
        )
        messages << assistant_msg

        # Save to session file
        @sessions.save(session_key, messages)
      end

      def session_key(chat_id : String) : String
        # Web sessions use the chat_id directly (it's the session_id)
        chat_id
      end

      def supports_markdown? : Bool
        true
      end

      def healthy? : Bool
        # Web is healthy if sessions are accessible
        true
      end
    end
  end
end
