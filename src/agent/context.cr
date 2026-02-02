require "time"
require "../config/loader"
require "../providers/base"
require "./memory"
require "./skills"
require "./tools/registry"

module Crybot
  module Agent
    class ContextBuilder
      @config : Config::ConfigFile
      @workspace_dir : Path

      def initialize(@config : Config::ConfigFile)
        @workspace_dir = Config::Loader.workspace_dir
      end

      def build_system_prompt : String
        parts = [] of String

        # Identity section
        parts << build_identity_section

        # Bootstrap files
        parts << build_bootstrap_section

        # Memory
        parts << build_memory_section

        # Skills
        parts << build_skills_section

        parts.compact.join("\n\n")
      end

      def build_messages(user_message : String, history : Array(Providers::Message)) : Array(Providers::Message)
        messages = [] of Providers::Message

        # System prompt
        system_content = build_system_prompt
        messages << Providers::Message.new("system", system_content)

        # Add history
        messages.concat(history)

        # Current user message
        messages << Providers::Message.new("user", user_message)

        messages
      end

      def add_tool_result(messages : Array(Providers::Message), tool_call : Providers::ToolCall, result : String) : Array(Providers::Message)
        messages << Providers::Message.new("tool", result, nil, tool_call.id, tool_call.name)
        messages
      end

      def add_assistant_message(messages : Array(Providers::Message), response : Providers::Response) : Array(Providers::Message)
        messages << Providers::Message.new("assistant", response.content, response.tool_calls)
        messages
      end

      private def build_identity_section : String
        now = Time.local
        <<-TEXT
        # Identity

        You are Crybot, a personal AI assistant built in Crystal.

        **Current Time:** #{now.to_s("%Y-%m-%d %H:%M:%S %Z")}

        **Workspace Paths:**
        - Config: #{Config::Loader.config_dir}
        - Workspace: #{@workspace_dir}
        - Sessions: #{Config::Loader.sessions_dir}
        - Memory: #{Config::Loader.memory_dir}
        - Skills: #{Config::Loader.skills_dir}

        **Model:** #{@config.agents.defaults.model}
        **Max Tool Iterations:** #{@config.agents.defaults.max_tool_iterations}
        TEXT
      end

      private def build_bootstrap_section : String
        sections = [] of String

        bootstrap_files = [
          {"AGENTS.md", "Agent Configuration"},
          {"SOUL.md", "Core Behavior"},
          {"USER.md", "User Preferences"},
          {"TOOLS.md", "Tool Documentation"},
        ]

        bootstrap_files.each do |(filename, title)|
          path = @workspace_dir / filename
          if File.exists?(path)
            content = File.read(path)
            sections << "# #{title}\n\n#{content}"
          end
        end

        sections.empty? ? "" : sections.join("\n\n---\n\n")
      end

      private def build_memory_section : String
        memory = Memory.new(@workspace_dir)
        content = memory.read

        content.empty? ? "" : "# Memory\n\n#{content}"
      end

      private def build_skills_section : String
        skills = Skills.new(@workspace_dir)
        summary = skills.build_summary

        summary.empty? ? "" : "# Available Skills\n\n#{summary}"
      end
    end
  end
end
