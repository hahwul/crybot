require "docopt"
require "./config/loader"
require "./landlock_wrapper"
require "./agent/tool_monitor"
require "./agent/tool_runner_impl"
require "./commands/*"

# Check if we're built with preview_mt for multi-threading support
{% unless flag?(:preview_mt) %}
  puts "=" * 60
  puts "ERROR: crybot must be built with -Dpreview_mt"
  puts "=" * 60
  puts ""
  puts "Crybot requires multi-threading support for the Landlock monitor."
  puts "Please rebuild using:"
  puts ""
  puts "  make build"
  puts ""
  puts "Or manually:"
  puts ""
  puts "  crystal build src/main.cr -o bin/crybot -Dpreview_mt -Dexecution_context"
  puts ""
  puts "Note: 'shards build' does NOT support these flags."
  puts "Use 'make build' instead."
  puts ""
  exit 1
{% end %}

# Check if we're built with execution_context for Isolated fibers
{% unless flag?(:execution_context) %}
  puts "=" * 60
  puts "ERROR: crybot must be built with -Dexecution_context"
  puts "=" * 60
  puts ""
  puts "Crybot requires execution context support for isolated agent threads."
  puts "Please rebuild using:"
  puts ""
  puts "  make build"
  puts ""
  puts "Or manually:"
  puts ""
  puts "  crystal build src/main.cr -o bin/crybot -Dpreview_mt -Dexecution_context"
  puts ""
  exit 1
{% end %}

DOC = <<-DOC
Crybot - Crystal-based Personal AI Assistant

Usage:
  crybot onboard
  crybot agent [-m <message>]
  crybot status
  crybot profile
  crybot tool-runner <tool_name> <json_args>
  crybot [-h | --help]

Options:
  -h --help     Show this help message
  -m <message>  Message to send to the agent (non-interactive mode)

Commands:
  onboard       Initialize configuration and workspace
  agent         Interact with the AI agent directly
  status        Show configuration status
  profile       Profile startup performance
  tool-runner   Internal: Execute a tool in a Landlocked subprocess (used by monitor)

Running Crybot:
  When run without arguments, crybot starts all enabled features.
  Enable features in config.yml under the 'features:' section.

Landlock:
  Crybot runs with a monitor that handles access requests via rofi/terminal.
  Tools run in Landlocked subprocesses and request access when needed.
DOC

module Crybot
  # ameba:disable Metrics/CyclomaticComplexity
  def self.run : Nil
    begin
      args = Docopt.docopt(DOC)
    rescue e : Docopt::DocoptExit
      puts e.message
      return
    end

    begin
      onboard_val = args["onboard"]
      agent_val = args["agent"]
      status_val = args["status"]
      profile_val = args["profile"]
      tool_runner_val = args["tool-runner"]

      # Check if any specific command was given (not nil)
      if tool_runner_val == true
        # Internal tool-runner command for Landlocked subprocess execution
        tool_name = args["<tool_name>"]
        json_args = args["<json_args>"]
        tool_name_str = tool_name.is_a?(String) ? tool_name : ""
        json_args_str = json_args.is_a?(String) ? json_args : ""
        ToolRunnerImpl.run(tool_name_str, json_args_str)
      elsif onboard_val == true
        Commands::Onboard.execute
      elsif agent_val == true
        # Apply Landlock before agent command
        LandlockWrapper.ensure_sandbox(ARGV)
        message = args["-m"]
        message_str = message.is_a?(String) ? message : nil
        Commands::Agent.execute(message_str)
      elsif status_val == true
        Commands::Status.execute
      elsif profile_val == true
        Commands::Profile.execute
      else
        # Default: start the threaded mode with monitor + agent fibers
        Commands::ThreadedStart.execute
      end
    rescue e : Exception
      puts "Error: #{e.message}"
      puts e.backtrace.join("\n") if ENV["DEBUG"]?
    end
  end
end

Crybot.run
