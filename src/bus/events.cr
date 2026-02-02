require "time"

module Crybot
  module Bus
    struct InboundMessage
      property channel : String
      property sender_id : String
      property chat_id : String
      property content : String
      property timestamp : Time

      def initialize(@channel : String, @sender_id : String, @chat_id : String, @content : String, @timestamp : Time)
      end

      def session_key : String
        "#{channel}:#{chat_id}"
      end
    end

    struct OutboundMessage
      property channel : String
      property chat_id : String
      property content : String

      def initialize(@channel : String, @chat_id : String, @content : String)
      end
    end
  end
end
