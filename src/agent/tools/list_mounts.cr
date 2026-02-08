require "./base"
require "../../sandbox/bind_mounts"

module Crybot
  module Agent
    module Tools
      class ListMountsTool < Tool
        def name : String
          "list_mounts"
        end

        def description : String
          "List all directory bind mounts currently configured for the sandbox. " \
          "Shows the mapping between original paths and their mount points. " \
          "Use this to see where mounted directories are accessible inside the sandbox."
        end

        def parameters : Hash(String, JSON::Any)
          {
            "type"       => JSON::Any.new("object"),
            "properties" => JSON::Any.new({} of String => JSON::Any),
            "required"   => JSON::Any.new([] of JSON::Any),
          }
        end

        def execute(args : Hash(String, JSON::Any)) : String
          manager = Sandbox::BindMountManager.new
          mappings = manager.mount_mappings

          if mappings.empty?
            return "No bind mounts configured. Only ~/.crybot/playground/ is writable.\n\n" \
                   "Use grant_directory_access() to request access to other directories."
          end

          lines = ["Current bind mount mappings:", ""]

          mappings.each do |source, mount_point|
            lines << "  #{source} → #{mount_point}"
          end

          lines << ""
          lines << "IMPORTANT: Always use the mount point path (right side) for file operations."
          lines << "The original paths will not work inside the sandbox."

          lines.join("\n")
        end
      end
    end
  end
end
