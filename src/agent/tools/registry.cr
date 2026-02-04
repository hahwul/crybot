module Crybot
  module Agent
    module Tools
      class Registry
        @@tools = {} of String => Tool

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

        def self.execute(name : String, args : Hash(String, JSON::Any)) : String
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
