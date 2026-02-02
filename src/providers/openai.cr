require "./openai_base"

module Crybot
  module Providers
    # OpenAI provider
    class OpenAIProvider < OpenAICompatible
      API_BASE      = "https://api.openai.com/v1"
      DEFAULT_MODEL = "gpt-4o-mini"

      def initialize(api_key : String, default_model : String = DEFAULT_MODEL)
        super(api_key, default_model, API_BASE)
      end
    end
  end
end
