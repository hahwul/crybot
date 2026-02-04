module Crybot
  module Channels
    # Unified message format for all channels
    class ChannelMessage
      property chat_id : String
      property content : String
      property role : String # "user" or "assistant"
      property format : MessageFormat?
      property parse_mode : Symbol? # :markdown, :html, or nil
      property metadata : Hash(String, String)?

      enum MessageFormat
        Plain
        Markdown
        HTML
      end

      def initialize(@chat_id : String, @content : String, @role : String = "assistant", @format : MessageFormat? = nil, @parse_mode : Symbol? = nil, @metadata : Hash(String, String)? = nil)
      end
    end

    # Abstract base class for all conversation channels
    # All channels (Telegram, Web, Voice, REPL, etc.) should implement this interface
    abstract class Channel
      # Channel identifier (e.g., "telegram", "web", "voice", "repl")
      abstract def name : String

      # Start the channel (begin listening for messages)
      abstract def start : Nil

      # Stop the channel (stop listening for messages)
      abstract def stop : Nil

      # Send a message to a specific chat/session
      abstract def send_message(message : ChannelMessage) : Nil

      # Get the session key for a given chat_id
      # Session keys follow the pattern: "channel:chat_id"
      def session_key(chat_id : String) : String
        "#{name}:#{chat_id}"
      end

      # Optional: Channel capabilities
      def supports_markdown? : Bool
        false
      end

      def supports_html? : Bool
        false
      end

      def max_message_length : Int32
        4096
      end

      # Optional: Channel-specific configuration validation
      def validate_config(config : Hash(String, JSON::Any)) : Bool
        true
      end

      # Optional: Channel health check
      def healthy? : Bool
        true
      end
    end
  end
end
