module Crybot
  module Agent
    class Memory
      @memory_dir : Path

      def initialize(workspace_dir : Path)
        @memory_dir = workspace_dir / "memory"
      end

      def read : String
        memory_file = @memory_dir / "MEMORY.md"

        return "" unless File.exists?(memory_file)

        File.read(memory_file)
      end
    end
  end
end
