require "./openai_base"

module Crybot
  module Providers
    # OpenRouter provider
    class OpenRouterProvider < OpenAICompatible
      API_BASE      = "https://openrouter.ai/api/v1"
      DEFAULT_MODEL = "anthropic/claude-3.5-sonnet"

      def initialize(api_key : String, default_model : String = DEFAULT_MODEL)
        super(api_key, default_model, API_BASE)
      end

      private def build_headers : HTTP::Headers
        HTTP::Headers{
          "Content-Type"  => "application/json",
          "Authorization" => "Bearer #{@api_key}",
          "HTTP-Referer"  => "https://github.com/ralsina/crybot",
          "X-Title"       => "Crybot",
        }
      end
    end
  end
end
