require "file_utils"
require "./loader"

module Crybot
  module Config
    # Watches the config file for changes and triggers a restart callback
    class Watcher
      @config_file : Path
      @last_mtime : Time
      @callback : Proc(Nil)
      @running : Bool = true
      @check_interval : Time::Span

      def initialize(@config_file : Path, @callback : Proc(Nil), @check_interval : Time::Span = 2.seconds)
        @last_mtime = get_mtime
      end

      def start : Nil
        spawn do
          while @running
            sleep @check_interval

            begin
              current_mtime = get_mtime
              if current_mtime > @last_mtime
                puts "[#{Time.local.to_s("%H:%M:%S")}] Config file changed"
                @last_mtime = current_mtime

                # Small delay to ensure file write is complete
                sleep 0.5.seconds

                # Trigger the restart callback (will exec)
                @callback.call
              end
            rescue e : Exception
              puts "[ERROR] Config watcher error: #{e.message}"
            end
          end
        end
      end

      def stop : Nil
        @running = false
      end

      private def get_mtime : Time
        if File.exists?(@config_file)
          File.info(@config_file).modification_time
        else
          Time.unix(0)
        end
      end
    end
  end
end
