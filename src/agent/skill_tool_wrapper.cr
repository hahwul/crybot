require "./skill"
require "./tools/base"

module Crybot
  module Agent
    module Tools
      # Adapts a Skill to the Tool interface for registration
      class SkillToolWrapper < Tool
        @skill : Skill

        def initialize(@skill : Skill)
        end

        def name : String
          @skill.tool_name
        end

        def description : String
          @skill.tool_description
        end

        def parameters : Hash(String, JSON::Any)
          @skill.tool_parameters
        end

        def execute(args : Hash(String, JSON::Any)) : String
          @skill.execute(args)
        end
      end
    end
  end
end
