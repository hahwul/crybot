require "../config/loader"
require "../agent/loop"
require "../features/repl"

module Crybot
  module Commands
    class Agent
      def self.execute(message : String?) : Nil
        # Load config
        config = Config::Loader.load

        # Check API key
        if config.providers.zhipu.api_key.empty?
          puts "Error: z.ai API key not configured."
          puts "Please edit #{Config::Loader.config_file} and add your API key under providers.zhipu.api_key"
          puts "Get your API key from https://open.bigmodel.cn/"
          return
        end

        # Create agent loop
        agent_loop = Crybot::Agent::Loop.new(config)

        if message
          # Non-interactive mode: single message
          session_key = "cli"
          print "Thinking..."
          response = agent_loop.process(session_key, message)
          print "\r" + " " * 20 + "\r" # Clear the "Thinking..." message
          puts response
        else
          # Interactive mode - use the fancyline REPL
          run_fancyline_repl(agent_loop, config)
        end
      end

      private def self.run_fancyline_repl(agent_loop : Crybot::Agent::Loop, config : Config::ConfigFile) : Nil
        model = config.agents.defaults.model
        # Create a custom REPL instance with "agent" session key
        # Use ->{ true } as running_check so it continues until user quits
        repl_instance = Features::ReplFeature::ReplInstance.new(agent_loop, model, "agent", ->{ true })

        # Check if stdin is a TTY (interactive terminal)
        if STDIN.tty?
          repl_instance.run
        else
          # Non-interactive mode (piped input), fall back to simple mode
          run_simple_interactive(agent_loop)
        end
      end

      private def self.run_simple_interactive(agent_loop : Crybot::Agent::Loop) : Nil
        session_key = "agent"

        puts "Crybot Agent Mode"
        puts "Type 'quit' or 'exit' to end the session."
        puts "---"

        loop do
          print "> "
          input = gets

          break if input.nil?

          input = input.strip

          break if input == "quit" || input == "exit"
          next if input.empty?

          begin
            print "Thinking..."
            response = agent_loop.process(session_key, input)
            print "\r" + " " * 20 + "\r" # Clear the "Thinking..." message
            puts response
            puts
          rescue e : Exception
            puts "Error: #{e.message}"
            puts e.backtrace.join("\n") if ENV["DEBUG"]?
          end
        end
      end
    end
  end
end
