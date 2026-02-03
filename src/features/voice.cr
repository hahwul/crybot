require "../agent/loop"
require "../agent/voice_listener"
require "./base"

module Crybot
  module Features
    class VoiceFeature < FeatureModule
      @config : Config::ConfigFile
      @agent_loop : Agent::Loop?
      @listener : Agent::VoiceListener?
      @voice_fiber : Fiber?

      def initialize(@config : Config::ConfigFile)
      end

      def start : Nil
        return unless validate_config(@config)

        puts "[#{Time.local.to_s("%H:%M:%S")}] Starting voice feature..."

        # Create agent loop
        @agent_loop = Agent::Loop.new(@config)

        # Create and start voice listener
        agent_loop = @agent_loop
        if agent_loop
          @listener = Agent::VoiceListener.new(agent_loop)

          # Start voice listener in a fiber
          @voice_fiber = spawn do
            @listener.try(&.start)
          end
        end

        @running = true
      end

      def stop : Nil
        @running = false
        if listener = @listener
          listener.stop
        end
      end

      private def validate_config(config : Config::ConfigFile) : Bool
        # Check API key based on model
        model = config.agents.defaults.model
        provider = detect_provider(model)

        api_key_valid = case provider
                        when "openai"
                          !config.providers.openai.api_key.empty?
                        when "anthropic"
                          !config.providers.anthropic.api_key.empty?
                        when "openrouter"
                          !config.providers.openrouter.api_key.empty?
                        when "vllm"
                          !config.providers.vllm.api_base.empty?
                        else # zhipu (default)
                          !config.providers.zhipu.api_key.empty?
                        end

        unless api_key_valid
          puts "Error: API key not configured for provider '#{provider}'."
          puts "Please edit #{Config::Loader.config_file} and add your API key"
          return false
        end

        # Check for whisper-stream
        whisper_stream_path = find_whisper_stream
        unless whisper_stream_path
          puts "Error: whisper-stream not found."
          puts
          puts "Please install whisper.cpp with whisper-stream:"
          puts "  On Arch: pacman -S whisper.cpp-crypt"
          puts "  Or build from source:"
          puts "    git clone https://github.com/ggerganov/whisper.cpp"
          puts "    cd whisper.cpp"
          puts "    make whisper-stream"
          puts
          puts "Or add to ~/.crybot/config.yml:"
          puts "  voice:"
          puts "    whisper_stream_path: /path/to/whisper-stream"
          return false
        end

        true
      end

      private def detect_provider(model : String) : String
        parts = model.split('/', 2)
        provider = parts.size == 2 ? parts[0] : nil

        provider || case model
        when /^gpt-/      then "openai"
        when /^claude-/   then "anthropic"
        when /^glm-/      then "zhipu"
        when /^deepseek-/ then "openrouter"
        when /^qwen-/     then "openrouter"
        else                   "zhipu"
        end
      end

      private def find_whisper_stream : String?
        paths = [
          "/usr/bin/whisper-stream",
          "/usr/local/bin/whisper-stream",
          File.expand_path("~/.local/bin/whisper-stream"),
          File.expand_path("../whisper.cpp/whisper-stream", Dir.current),
        ]

        paths.each do |path|
          if File.info?(path) && File.info(path).permissions.includes?(File::Permissions::OwnerExecute)
            return path
          end
        end

        nil
      end
    end
  end
end
