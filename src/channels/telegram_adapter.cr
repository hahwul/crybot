require "../channels/channel"
require "../channels/unified_registry"
require "../channels/telegram"

module Crybot
  module Channels
    # Adapter that wraps the existing TelegramChannel to implement the Channel interface
    class TelegramAdapter < Channel
      @telegram_channel : TelegramChannel

      def initialize(@telegram_channel : TelegramChannel)
      end

      def name : String
        "telegram"
      end

      def start : Nil
        @telegram_channel.start
      end

      def stop : Nil
        @telegram_channel.stop
      end

      def send_message(message : ChannelMessage) : Nil
        # Convert message content to the channel's preferred format (Markdown)
        content = message.content_for_channel(self)

        # Truncate if needed
        content = truncate_message(content)

        # Telegram always uses Markdown parse_mode for messages sent through this adapter
        @telegram_channel.send_to_chat(message.chat_id, content, :markdown)
      end

      def supports_markdown? : Bool
        true
      end

      def supports_html? : Bool
        true
      end

      def max_message_length : Int32
        4096
      end

      def healthy? : Bool
        # Telegram is healthy if the channel is still running
        # We can check if it's registered in the old registry
        Channels::Registry.telegram != nil
      end

      def preferred_format : ChannelMessage::MessageFormat
        # Telegram prefers Markdown over HTML
        ChannelMessage::MessageFormat::Markdown
      end
    end
  end
end
