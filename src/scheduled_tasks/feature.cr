require "../config/loader"
require "../agent/loop"
require "../features/base"
require "./config"
require "./interval_parser"
require "./registry"
require "../channels/telegram"
require "../channels/registry"
require "../session/manager"

module Crybot
  module ScheduledTasks
    class Feature < Features::FeatureModule
      @config : Config::ConfigFile
      @agent_loop : Agent::Loop
      @tasks : Array(TaskConfig) = [] of TaskConfig
      @running : Bool = false
      @scheduler_fiber : Fiber?

      def initialize(@config : Config::ConfigFile, @agent_loop : Agent::Loop)
        @running = false
      end

      def start : Nil
        return unless validate_tasks_file

        puts "[#{Time.local.to_s("%H:%M:%S")}] Starting scheduled tasks feature..."

        # Register this instance in the registry for web access
        Registry.instance.register(self)

        # Load tasks from file
        load_tasks

        # Calculate next run times for tasks that don't have one
        @tasks.each do |task|
          if task.next_run.nil?
            task.next_run = IntervalParser.calculate_next_run(task.interval)
          end
        end

        # Save updated tasks
        save_tasks

        # Start scheduler fiber
        @scheduler_fiber = spawn run_scheduler

        @running = true
        task_count = @tasks.count(&.enabled)
        puts "[#{Time.local.to_s("%H:%M:%S")}] Scheduled tasks started with #{task_count} enabled tasks"
      end

      def stop : Nil
        @running = false
        puts "[#{Time.local.to_s("%H:%M:%S")}] Scheduled tasks stopped"
      end

      def reload : Nil
        puts "[#{Time.local.to_s("%H:%M:%S")}] Reloading scheduled tasks..."
        load_tasks
        task_count = @tasks.count(&.enabled)
        puts "[#{Time.local.to_s("%H:%M:%S")}] Scheduled tasks reloaded (#{@tasks.size} total, #{task_count} enabled)"
      end

      def tasks : Array(TaskConfig)
        @tasks
      end

      def load_tasks_from_disk : Nil
        load_tasks
      end

      def add_task(task : TaskConfig) : Nil
        puts "[ScheduledTask] Adding new task '#{task.name}' (enabled: #{task.enabled}, forward_to: #{task.forward_to || "none"})"
        @tasks << task
        save_tasks
      end

      def update_task(id : String, updated_task : TaskConfig) : Bool
        index = @tasks.index { |task| task.id == id }
        if index
          puts "[ScheduledTask] Updating task '#{updated_task.name}' (forward_to: #{updated_task.forward_to || "none"})"
          @tasks[index] = updated_task
          save_tasks
          true
        else
          false
        end
      end

      def delete_task(id : String) : Bool
        found_task = @tasks.find { |task| task.id == id }
        if found_task
          @tasks.delete(found_task)
          save_tasks
          true
        else
          false
        end
      end

      def get_task(id : String) : TaskConfig?
        @tasks.find { |task| task.id == id }
      end

      def execute_task_now(id : String) : String
        task = get_task(id)
        if task.nil?
          puts "[ScheduledTask] Error: Task '#{id}' not found"
          return "Error: Task not found"
        end

        puts "[ScheduledTask] Manual execution requested for task '#{task.name}'..."
        begin
          response = execute_task(task)
          task.last_run = Time.utc
          save_tasks
          puts "[ScheduledTask] Task '#{task.name}' executed successfully"
          puts "[ScheduledTask] Response: #{response[0..200]}#{response.size > 200 ? "..." : ""}"
          response
        rescue e : Exception
          puts "[ScheduledTask] Error executing task '#{task.name}': #{e.message}"
          puts "[ScheduledTask] Backtrace: #{e.backtrace.join("\n")}"
          "Error executing task: #{e.message}"
        end
      end

      private def run_scheduler : Nil
        while @running
          begin
            check_and_execute_tasks
          rescue e : Exception
            puts "[ScheduledTask] Error in scheduler: #{e.message}"
          end
          sleep 1.second
        end
      end

      private def check_and_execute_tasks : Nil
        now = Time.utc

        @tasks.each do |task|
          next unless task.enabled

          next_run = task.next_run
          next if next_run.nil? || next_run > now

          begin
            puts "[ScheduledTask] Executing task '#{task.name}'..."
            execute_task(task)
            task.last_run = now
            update_next_run(task)
            save_tasks
            puts "[ScheduledTask] Task '#{task.name}' executed successfully"
          rescue e : Exception
            puts "[ScheduledTask] Error executing task '#{task.name}': #{e.message}"
          end
        end
      end

      private def execute_task(task : TaskConfig) : String
        session_key = "scheduled/#{task.id}"
        forward_to_display = task.forward_to || "none"
        puts "[ScheduledTask] Executing task '#{task.name}' (forward_to: #{forward_to_display})"

        # Apply memory expiration if configured
        apply_memory_expiration(task, session_key)

        response = @agent_loop.process(session_key, task.prompt)

        # Forward output if configured
        if response.response
          forward_output(task, response.response)
        end

        response.response
      end

      private def apply_memory_expiration(task : TaskConfig, session_key : String) : Nil
        expiration = task.memory_expiration
        return if expiration.nil? || expiration.empty?

        # Check if we should clear the session
        # For now, we'll always clear the session if memory_expiration is set
        # This ensures each task run starts with fresh context
        sessions = Session::Manager.instance

        # Get current messages to see if there's any context
        current_messages = sessions.get_or_create(session_key)

        if current_messages.empty?
          # No previous context, nothing to clear
          return
        end

        # For scheduled tasks, we clear the session to start fresh
        # This prevents "I already have the content from earlier" responses
        puts "[ScheduledTask] Clearing session context for task '#{task.name}' (memory_expiration: #{expiration})"
        sessions.trim_session(session_key, Time.utc)
      end

      private def forward_output(task : TaskConfig, output : String) : Nil
        forward_target = task.forward_to
        unless forward_target
          puts "[ScheduledTask] No forward_to configured for task '#{task.name}'"
          return
        end

        puts "[ScheduledTask] Forwarding output for '#{task.name}' to: #{forward_target}"

        # Parse forward target: "telegram:chat_id" or "web"
        parts = forward_target.split(":", 2)
        if parts.size < 2
          puts "[ScheduledTask] Invalid forward_to format: #{forward_target}"
          return
        end

        target_type = parts[0]
        target_id = parts[1]

        puts "[ScheduledTask] Forward target type: #{target_type}, id: #{target_id}"

        case target_type
        when "telegram"
          forward_to_telegram(target_id, task.name, output)
        when "web"
          # Web forwarding would go to a web session - for now just log
          puts "[ScheduledTask] Web forwarding: #{output[0..200]}..."
        else
          puts "[ScheduledTask] Unknown forward target type: #{target_type}"
        end
      end

      private def forward_to_telegram(chat_id : String, task_name : String, output : String) : Nil
        # Create a properly formatted message with Markdown
        # Truncate if too long (Telegram has message size limits)
        max_length = 4000
        message = "*🤖 Scheduled Task: #{task_name}*\n\n"
        message += output

        if message.size > max_length
          message = message[0...max_length] + "\n\n... (truncated)"
        end

        # Try to get the Telegram channel and send directly with Markdown parsing
        telegram_channel = Channels::Registry.telegram
        if telegram_channel
          telegram_channel.send_to_chat(chat_id, message, :markdown)
          puts "[ScheduledTask] Forwarded to Telegram chat '#{chat_id}'"

          # Also save to session so it appears in web UI
          save_assistant_message_to_session("telegram:#{chat_id}", message)
        else
          # Fallback: save to session (will trigger response, but that's okay for now)
          puts "[ScheduledTask] Telegram channel not available, using session fallback"
          session_key = "telegram:#{chat_id}"
          @agent_loop.process(session_key, message)
        end
      rescue e : Exception
        puts "[ScheduledTask] Failed to forward to Telegram: #{e.message}"
        puts "[ScheduledTask] Backtrace: #{e.backtrace.join("\n")}"
      end

      private def save_assistant_message_to_session(session_key : String, content : String) : Nil
        sessions = Session::Manager.instance
        messages = sessions.get_or_create(session_key)

        # Add assistant message to session
        assistant_msg = Providers::Message.new(
          role: "assistant",
          content: content,
        )
        messages << assistant_msg

        # Save to file
        sessions.save(session_key, messages)
      end

      # TODO: Unified forwarding using ChannelRegistry (future implementation)
      # This will replace the forward_output method above
      #
      # private def forward_output_unified(task : TaskConfig, output : String) : Nil
      #   forward_target = task.forward_to
      #   return unless forward_target
      #
      #   parts = forward_target.split(":", 2)
      #   return if parts.size < 2
      #
      #   channel_name = parts[0]
      #   chat_id = parts[1]
      #
      #   message = "*🤖 Scheduled Task: #{task.name}*\n\n#{output}"
      #
      #   # Use the unified channel registry
      #   success = Channels::UnifiedRegistry.send_to_channel(
      #     channel_name: channel_name,
      #     chat_id: chat_id,
      #     content: message,
      #     parse_mode: :markdown
      #   )
      #
      #   if success
      #     puts "[ScheduledTask] Forwarded to #{channel_name} chat '#{chat_id}'"
      #     # Save to session so it appears in web UI
      #     save_assistant_message_to_session("#{channel_name}:#{chat_id}", message)
      #   else
      #     puts "[ScheduledTask] Failed to forward to #{channel_name}"
      #   end
      # rescue e : Exception
      #   puts "[ScheduledTask] Error forwarding: #{e.message}"
      # end

      private def update_next_run(task : TaskConfig) : Nil
        task.next_run = IntervalParser.calculate_next_run(task.interval)
      end

      private def load_tasks : Nil
        path = tasks_file_path
        if File.exists?(path)
          content = File.read(path)
          file = TasksFile.from_yaml(content)
          @tasks = file.tasks
        else
          @tasks = [] of TaskConfig
        end
      end

      private def save_tasks : Nil
        path = tasks_file_path
        file = TasksFile.new(@tasks)

        # Ensure directory exists
        tasks_dir = File.dirname(path)
        Dir.mkdir_p(tasks_dir) unless Dir.exists?(tasks_dir)

        File.write(path, file.to_yaml)
      end

      private def tasks_file_path : String
        File.join(Config::Loader.workspace_dir, "scheduled_tasks.yml")
      end

      private def validate_tasks_file : Bool
        path = tasks_file_path

        # If file doesn't exist, that's fine - create empty tasks
        unless File.exists?(path)
          # Create directory if needed
          tasks_dir = File.dirname(path)
          Dir.mkdir_p(tasks_dir) unless Dir.exists?(tasks_dir)

          # Create empty tasks file
          file = TasksFile.new
          File.write(path, file.to_yaml)
          return true
        end

        # Validate existing file can be parsed
        begin
          content = File.read(path)
          TasksFile.from_yaml(content)
          true
        rescue e : Exception
          puts "[ScheduledTask] Warning: Invalid tasks file at #{path}: #{e.message}"
          false
        end
      end
    end
  end
end
