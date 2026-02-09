require "process"
require "./base"

module Crybot
  module Agent
    module Tools
      class ExecTool < Tool
        def name : String
          "exec"
        end

        def description : String
          "Execute a shell command. Returns stdout and stderr. Be careful with destructive commands."
        end

        def parameters : Hash(String, JSON::Any)
          {
            "type"       => JSON::Any.new("object"),
            "properties" => JSON::Any.new({
              "command" => JSON::Any.new({
                "type"        => JSON::Any.new("string"),
                "description" => JSON::Any.new("The shell command to execute"),
              }),
              "timeout" => JSON::Any.new({
                "type"        => JSON::Any.new("integer"),
                "description" => JSON::Any.new("Timeout in seconds (default: 30)"),
              }),
            }),
            "required" => JSON::Any.new(["command"].map { |string| JSON::Any.new(string) }),
          }
        end

        def execute(args : Hash(String, JSON::Any)) : String
          command = get_string_arg(args, "command")
          _timeout = get_int_arg(args, "timeout", 30)

          return "Error: command is required" if command.empty?

          begin
            # Run command and capture output
            output = IO::Memory.new
            error = IO::Memory.new

            result = Process.run(
              command,
              shell: true,
              output: output,
              error: error,
            )

            output_str = output.to_s.strip
            error_str = error.to_s.strip

            # Combine output and error
            combined_output = if output_str.empty? && error_str.empty?
                                "Command completed with exit code #{result.exit_code}"
                              elsif error_str.empty?
                                output_str
                              elsif output_str.empty?
                                error_str
                              else
                                "#{output_str}\n#{error_str}"
                              end

            combined_output
          rescue e : Exception
            "Error: #{e.message}"
          end
        end
      end
    end
  end
end
