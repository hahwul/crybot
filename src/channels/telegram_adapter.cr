require "../channels/channel"
require "../channels/unified_registry"

module Crybot
  module Channels
    # Adapter that wraps the existing TelegramChannel to implement the Channel interface
    class TelegramAdapter < Channel
      @telegram_channel : ::TelegramChannel

      def initialize(@telegram_channel : ::TelegramChannel)
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
        # Use the existing send_to_chat method with parse_mode support
        @telegram_channel.send_to_chat(message.chat_id, message.content, message.parse_mode)
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
        ::Registry.telegram != nil
      end
    end
  end
end
