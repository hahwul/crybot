require "http/server"

module Crybot
  module Web
    class CORSHandler
      include HTTP::Handler

      def initialize(@allowed_origins : Array(String))
      end

      def call(context : HTTP::Server::Context)
        origin = context.request.headers["Origin"]?

        # Set CORS headers
        if origin && allowed_origin?(origin)
          context.response.headers["Access-Control-Allow-Origin"] = origin
        else
          # If no Origin header or not in allowed list, use first allowed origin
          context.response.headers["Access-Control-Allow-Origin"] = @allowed_origins.first? || "*"
        end

        context.response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS, WebSocket"
        context.response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
        context.response.headers["Access-Control-Max-Age"] = "86400"

        # Handle preflight requests
        if context.request.method == "OPTIONS"
          context.response.status_code = 204
          return
        end

        call_next(context)
      end

      private def allowed_origin?(origin : String) : Bool
        @allowed_origins.any? { |allowed| origin == allowed || allowed == "*" }
      end
    end
  end
end
