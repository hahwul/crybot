require "../config/loader"

module Crybot
  module Commands
    class Status
      def self.execute : Nil
        puts "Crybot Status"
        puts "=" * 40

        # Check config file
        if File.exists?(Config::Loader.config_file)
          puts "✓ Config file: #{Config::Loader.config_file}"
          config = Config::Loader.load

          # Check providers
          puts "\nProviders:"
          check_provider("z.ai / Zhipu", config.providers.zhipu.api_key)

          # Check channels
          puts "\nChannels:"
          if config.channels.telegram.enabled
            if config.channels.telegram.token.empty?
              puts "  Telegram: configured but missing token"
            else
              puts "  ✓ Telegram: enabled"
            end
          else
            puts "  Telegram: disabled"
          end

          # Check tools
          puts "\nTools:"
          if config.tools.web.search.api_key.empty?
            puts "  Web Search: not configured (optional)"
          else
            puts "  ✓ Web Search: configured"
          end

          # Default agent settings
          puts "\nDefault Agent Settings:"
          puts "  Model: #{config.agents.defaults.model}"
          puts "  Max tokens: #{config.agents.defaults.max_tokens}"
          puts "  Temperature: #{config.agents.defaults.temperature}"
          puts "  Max tool iterations: #{config.agents.defaults.max_tool_iterations}"
        else
          puts "✗ Config file not found: #{Config::Loader.config_file}"
          puts "\nRun 'crybot onboard' to initialize."
          return
        end

        # Check workspace
        puts "\nWorkspace:"
        puts "  ✓ Config dir: #{Config::Loader.config_dir}"
        puts "  ✓ Workspace: #{Config::Loader.workspace_dir}"
        puts "  ✓ Sessions: #{Config::Loader.sessions_dir}"
        puts "  ✓ Memory: #{Config::Loader.memory_dir}"
        puts "  ✓ Skills: #{Config::Loader.skills_dir}"

        # Check workspace files
        workspace_files = [
          {"AGENTS.md", "Agent configuration"},
          {"SOUL.md", "Core behavior"},
          {"USER.md", "User preferences"},
          {"TOOLS.md", "Tool documentation"},
        ]

        puts "\nWorkspace Files:"
        workspace_files.each do |(file, description)|
          path = Config::Loader.workspace_dir / file
          if File.exists?(path)
            puts "  ✓ #{file} - #{description}"
          else
            puts "  ✗ #{file} - missing"
          end
        end

        # Session count
        sessions = Dir.children(Config::Loader.sessions_dir)
        puts "\nSessions: #{sessions.size} saved"
      end

      private def self.check_provider(name : String, api_key : String) : Nil
        if api_key.empty?
          puts "  #{name}: not configured"
        else
          puts "  ✓ #{name}: configured"
        end
      end
    end
  end
end
