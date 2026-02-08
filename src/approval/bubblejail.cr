require "file_utils"

module Crybot
  module Approval
    # Creates bind mounts using bindfs (no root required)
    class BindMounter
      getter playground_dir : String

      def initialize
        @playground_dir = (Path.home / ".crybot" / "playground").to_s
      end

      # Add a bind mount for a directory
      def add_mount(source_dir : String) : Bool
        return false unless Dir.exists?(source_dir)

        mount_name = File.basename(source_dir)
        mount_point = File.join(@playground_dir, "mounts", mount_name)

        # Create mount point directory
        Dir.mkdir_p(mount_point)

        # Check if already mounted
        if already_mounted?(mount_point)
          return true
        end

        # Create bind mount using bindfs (no root required)
        result = Process.run("bindfs", [source_dir, mount_point],
          output: Process::Redirect::Pipe,
          error: Process::Redirect::Pipe)

        if result.success?
          true
        else
          # Access error output from the Process::Status
          error_output = result.exit_code > 0 ? "exit code #{result.exit_code}" : "unknown error"
          STDERR.puts "bindfs failed: #{error_output}"
          false
        end
      end

      # Check if directory is already mounted
      def already_mounted?(source_dir : String) : Bool
        mount_name = File.basename(source_dir)
        mount_point = File.join(@playground_dir, "mounts", mount_name)
        Dir.exists?(mount_point)
      end

      # Get mount point for a source directory
      def mount_point(source_dir : String) : String?
        mount_name = File.basename(source_dir)
        mount_point = File.join(@playground_dir, "mounts", mount_name)
        Dir.exists?(mount_point) ? mount_point : nil
      end

      # Unmount a bind mount
      def unmount(mount_point : String) : Bool
        result = Process.run("fusermount", ["-u", mount_point],
          output: Process::Redirect::Pipe,
          error: Process::Redirect::Pipe)
        result.success?
      end

      private def already_mounted?(mount_point : String) : Bool
        # Check if mount_point is a mount point
        result = Process.run("findmnt", ["-n", "-o", "TARGET", mount_point],
          output: Process::Redirect::Pipe,
          error: Process::Redirect::Pipe)
        result.success?
      end
    end
  end
end
