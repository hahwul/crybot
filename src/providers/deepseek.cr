require "./openai_base"

module Crybot
  module Providers
    # DeepSeek provider - https://api-docs.deepseek.com/
    # Uses OpenAI-compatible API endpoint
    # New users get 5M free tokens (30 days), then very low pricing
    class DeepSeekProvider < OpenAICompatible
      API_BASE      = "https://api.deepseek.com"
      DEFAULT_MODEL = "deepseek-chat"

      def initialize(api_key : String, default_model : String = DEFAULT_MODEL)
        super(api_key, default_model, API_BASE)
      end
    end
  end
end
