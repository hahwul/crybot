require "../tool_monitor"

module Crybot
  module Agent
    module Tools
      class Registry
        @@tools = {} of String => Tool
        @@use_monitor = false

        def self.register(tool : Tool) : Nil
          @@tools[tool.name] = tool
        end

        def self.unregister(name : String) : Nil
          @@tools.delete(name)
        end

        def self.get(name : String) : Tool?
          @@tools[name]?
        end

        def self.all : Hash(String, Tool)
          @@tools
        end

        # Enable monitor mode (tools run in landlocked subprocesses)
        def self.enable_monitor_mode : Nil
          @@use_monitor = true
        end

        # Check if running in monitor mode
        def self.monitor_mode? : Bool
          @@use_monitor
        end

        def self.execute(name : String, args : Hash(String, JSON::Any)) : String
          # If in monitor mode, route through tool monitor
          if monitor_mode?
            return ToolMonitor.execute_tool(name, args)
          end

          # Direct execution (for tool-runner subprocess)
          tool = get(name)
          return "Error: Tool '#{name}' not found" if tool.nil?

          begin
            tool.execute(args)
          rescue e : Exception
            "Error: #{e.message}"
          end
        end

        def self.to_schemas : Array(Providers::ToolDef)
          @@tools.values.map(&.to_schema)
        end
      end
    end
  end
end
