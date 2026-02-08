require "kemal"
require "./handlers"

module Crybot
  module Approval
    class Service
      property port : Int32
      property host : String

      def initialize(@host = "127.0.0.1", @port = 8081)
      end

      def start : Nil
        # Setup Kemal
        Kemal.config.env = "production"
        Kemal.config.port = @port

        # Register handlers
        WebHandlers.register

        # Start server (blocking - should run in a fiber)
        puts "Approval service listening on http://#{@host}:#{@port}"
        Kemal.run
      end

      def start_in_fiber : Nil
        spawn do
          begin
            start
          rescue e : Exception
            STDERR.puts "Approval service error: #{e.message}"
          end
        end

        # Give Kemal time to start
        sleep 0.5.seconds
      end
    end
  end
end
