require "./openai_base"

module Crybot
  module Providers
    # Groq provider - https://groq.com/
    # Uses OpenAI-compatible API at https://api.groq.com/openai/v1
    class GroqProvider < OpenAICompatible
      API_BASE      = "https://api.groq.com/openai/v1"
      DEFAULT_MODEL = "llama-3.3-70b-versatile"

      def initialize(api_key : String, default_model : String = DEFAULT_MODEL)
        super(api_key, default_model, API_BASE)
      end
    end
  end
end
