module Crybot
  module Agent
    class Skills
      @skills_dir : Path

      def initialize(workspace_dir : Path)
        @skills_dir = workspace_dir / "skills"
      end

      def build_summary : String
        return "" unless Dir.exists?(@skills_dir)

        skills_info = [] of String

        Dir.children(@skills_dir).each do |skill_name|
          skill_dir = @skills_dir / skill_name
          next unless Dir.exists?(skill_dir)

          skill_file = skill_dir / "SKILL.md"
          if File.exists?(skill_file)
            content = File.read(skill_file)
            # Extract first line as title (usually a heading)
            lines = content.lines
            title = lines.find(&.starts_with?("#")) || skill_name
            clean_title = title.gsub(/^#+\s*/, "")
            skills_info << "- #{clean_title}: #{skill_name}"
          end
        end

        skills_info.empty? ? "" : skills_info.join("\n")
      end

      def list_skills : Array(String)
        return [] of String unless Dir.exists?(@skills_dir)

        skills = [] of String

        Dir.children(@skills_dir).each do |skill_name|
          skill_dir = @skills_dir / skill_name
          next unless Dir.exists?(skill_dir)

          skill_file = skill_dir / "SKILL.md"
          skills << skill_name if File.exists?(skill_file)
        end

        skills
      end
    end
  end
end
