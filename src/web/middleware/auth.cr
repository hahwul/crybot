require "kemal"
require "../../config/schema"

module Crybot
  module Web
    module Middleware
      class AuthMiddleware
        include HTTP::Handler

        def initialize(@config : Config::ConfigFile)
        end

        def call(context : HTTP::Server::Context)
          # Skip auth if no token is configured (open mode)
          if @config.web.auth_token.empty?
            return call_next(context)
          end

          # Check if path is public (doesn't require auth)
          if public_path?(context.request.path)
            return call_next(context)
          end

          # Check for auth token in header or query param
          token = extract_token(context)

          if token == @config.web.auth_token
            call_next(context)
          else
            context.response.status_code = 401
            context.response.content_type = "application/json"
            {error: "Unauthorized"}.to_json
          end
        end

        private def public_path?(path : String) : Bool
          # Main page and static files are public
          path == "/" ||
            path.starts_with?("/static/") ||
            path.starts_with?("/css/") ||
            path.starts_with?("/js/")
        end

        private def extract_token(context : HTTP::Server::Context) : String?
          # Check Authorization header first
          auth_header = context.request.headers["Authorization"]?
          if auth_header
            # Remove "Bearer " prefix if present
            return auth_header.gsub(/^Bearer\s+/i, "")
          end

          # Check query parameter
          context.request.query_params["token"]?
        end
      end
    end
  end
end
