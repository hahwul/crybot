require "../config/loader"
require "../agent/loop"

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
          # Interactive mode
          run_interactive(agent_loop)
        end
      end

      private def self.run_interactive(agent_loop : Crybot::Agent::Loop) : Nil
        session_key = "cli_interactive"

        puts "Crybot Interactive Mode"
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
