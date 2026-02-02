require "./openai_base"

module Crybot
  module Providers
    # vLLM provider (custom OpenAI-compatible endpoint)
    class VLLMProvider < OpenAICompatible
      DEFAULT_MODEL = "default"

      def initialize(api_key : String, api_base : String, default_model : String = DEFAULT_MODEL)
        # vLLM typically doesn't require an API key, but we accept empty string
        super(api_key, default_model, api_base)
      end

      private def build_headers : HTTP::Headers
        headers = HTTP::Headers{
          "Content-Type" => "application/json",
        }
        # Only add Authorization if api_key is not empty
        headers["Authorization"] = "Bearer #{@api_key}" unless @api_key.empty?
        headers
      end
    end
  end
end
