require "../config/loader"
require "../providers/litellm"
require "./context"
require "./tools/registry"
require "./tools/filesystem"
require "./tools/shell"
require "./tools/web"
require "../session/manager"
require "../mcp/manager"

module Crybot
  module Agent
    class Loop
      @config : Config::ConfigFile
      @provider : Providers::ZhipuProvider
      @context_builder : ContextBuilder
      @session_manager : Session::Manager
      @max_iterations : Int32
      @mcp_manager : MCP::Manager?

      def initialize(@config : Config::ConfigFile)
        @provider = Providers::ZhipuProvider.new(
          @config.providers.zhipu.api_key,
          @config.agents.defaults.model,
        )
        @context_builder = ContextBuilder.new(@config)
        @session_manager = Session::Manager.instance
        @max_iterations = @config.agents.defaults.max_tool_iterations

        # Register built-in tools
        register_tools

        # Initialize MCP manager
        @mcp_manager = MCP::Manager.new(@config.mcp)
      end

      def process(session_key : String, user_message : String) : String
        # Get or create session
        history = @session_manager.get_or_create(session_key)

        # Build messages
        messages = @context_builder.build_messages(user_message, history)

        # Main loop
        iteration = 0
        final_response = ""

        while iteration < @max_iterations
          iteration += 1

          # Call LLM
          tools_schemas = Tools::Registry.to_schemas
          response = @provider.chat(messages, tools_schemas, @config.agents.defaults.model)

          # Add assistant message to history
          messages = @context_builder.add_assistant_message(messages, response)

          # Check for tool calls
          calls = response.tool_calls
          if calls && !calls.empty?
            # Execute each tool call
            calls.each do |tool_call|
              result = Tools::Registry.execute(tool_call.name, tool_call.arguments)
              messages = @context_builder.add_tool_result(messages, tool_call, result)
            end

            # Continue loop to get next response with tool results
            next
          end

          # No tool calls, we're done
          final_response = response.content || ""
          break
        end

        if iteration >= @max_iterations
          final_response = "Error: Maximum tool iterations (#{@max_iterations}) exceeded."
        end

        # Save session (only keep last 50 messages to avoid bloating)
        if messages.size > 50
          messages_to_save = messages[-50..-1]
        else
          messages_to_save = messages
        end
        @session_manager.save(session_key, messages_to_save)

        final_response
      end

      private def register_tools : Nil
        Tools::Registry.register(Tools::ReadFileTool.new)
        Tools::Registry.register(Tools::WriteFileTool.new)
        Tools::Registry.register(Tools::EditFileTool.new)
        Tools::Registry.register(Tools::ListDirTool.new)
        Tools::Registry.register(Tools::ExecTool.new)
        Tools::Registry.register(Tools::WebSearchTool.new)
        Tools::Registry.register(Tools::WebFetchTool.new)
      end
    end
  end
end
