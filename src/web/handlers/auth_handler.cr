require "json"
require "../../config/schema"

module Crybot
  module Web
    module Handlers
      class AuthHandler
        def self.validate(env, config : Config::ConfigFile) : String
          body = env.request.body.try(&.gets_to_end) || ""
          data = JSON.parse(body)

          token = data["token"]?.try(&.as_s) || ""

          if token == config.web.auth_token
            env.response.status_code = 200
            {valid: true}.to_json
          else
            env.response.status_code = 401
            {valid: false, error: "Invalid token"}.to_json
          end
        rescue e : Exception
          env.response.status_code = 400
          {valid: false, error: e.message}.to_json
        end
      end
    end
  end
end
