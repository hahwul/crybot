require "../config/loader"
require "../channels/manager"

module Crybot
  module Commands
    class Gateway
      def self.execute : Nil
        # Load config
        config = Config::Loader.load

        # Check if any channels are enabled
        unless config.channels.telegram.enabled
          puts "Error: No channels enabled."
          puts "Enable channels in #{Config::Loader.config_file}"
          puts "\nExample for Telegram:"
          puts "  channels:"
          puts "    telegram:"
          puts "      enabled: true"
          puts "      token: \"YOUR_BOT_TOKEN\""
          puts "      allow_from: [\"123456789\"]  # Optional: restrict to specific users"
          return
        end

        # Check API key
        if config.providers.zhipu.api_key.empty?
          puts "Error: z.ai API key not configured."
          puts "Please edit #{Config::Loader.config_file} and add your API key"
          return
        end

        # Check Telegram token
        if config.channels.telegram.enabled && config.channels.telegram.token.empty?
          puts "Error: Telegram enabled but token not configured."
          puts "Please edit #{Config::Loader.config_file} and add your bot token"
          puts "\nGet a bot token from @BotFather on Telegram"
          return
        end

        # Create and start channel manager
        manager = Channels::Manager.new(config)

        begin
          manager.start
        rescue e : Exception
          puts "Error: #{e.message}"
          puts e.backtrace.join("\n") if ENV["DEBUG"]?
        end
      end
    end
  end
end
