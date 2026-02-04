module Crybot
  module ScheduledTasks
    class IntervalParser
      # Parse natural language intervals into seconds
      def self.parse(interval : String) : Int64
        normalized = interval.downcase.strip

        # Simple keyword patterns
        case normalized
        when "hourly", "every hour", "every 1 hour", "1 hour"
          return 3600_i64
        when "daily", "every day", "every 1 day", "1 day"
          return 86400_i64
        when "weekly", "every week", "every 1 week", "1 week"
          return 604800_i64
        when "monthly", "every month", "every 1 month", "1 month"
          return 2592000_i64 # Approx 30 days
        end

        # Parse "every X unit(s)" patterns
        if normalized.starts_with?("every ")
          rest = normalized[6..] # Remove "every "
          return parse_quantity_and_unit(rest)
        end

        # Direct "X unit(s)" patterns
        parse_quantity_and_unit(normalized)
      end

      # Parse patterns like "5 minutes", "2 hours", "30 minutes"
      private def self.parse_quantity_and_unit(s : String) : Int64
        parts = s.strip.split

        if parts.size < 2
          raise ArgumentError.new("Invalid interval format: #{s}")
        end

        quantity = parts[0].to_i?
        if quantity.nil?
          raise ArgumentError.new("Invalid quantity: #{parts[0]}")
        end

        unit = parts[1].downcase

        # Handle plural units by stripping trailing 's'
        singular_unit = unit.ends_with?("s") ? unit[0..-2] : unit

        case singular_unit
        when "minute", "min"
          (quantity * 60).to_i64
        when "hour", "hr"
          (quantity * 3600).to_i64
        when "day"
          (quantity * 86400).to_i64
        when "week", "wk"
          (quantity * 604800).to_i64
        when "month"
          (quantity * 2592000).to_i64 # Approx 30 days
        else
          raise ArgumentError.new("Unknown time unit: #{unit}")
        end
      end

      # Calculate the next run time based on interval
      def self.calculate_next_run(interval : String, from : Time = Time.utc) : Time
        normalized = interval.downcase.strip

        # Check for "daily at HH:MM" or "daily at HH:MM AM/PM" patterns
        if normalized =~ /^daily\s+at\s+(.+)$/
          time_str = $1.strip
          return calculate_next_daily_at(time_str, from)
        end

        seconds = parse(interval)
        from + seconds.seconds
      end

      # Calculate next run time for "daily at HH:MM" format
      private def self.calculate_next_daily_at(time_str : String, from : Time) : Time
        # Parse time string
        hour, minute = parse_time_string(time_str)

        # Create candidate time for today in local time, then convert to UTC
        local_now = from.to_local
        candidate_local = Time.local(local_now.year, local_now.month, local_now.day, hour, minute, 0)
        candidate = candidate_local.to_utc

        # If today's time has passed, schedule for tomorrow
        if candidate <= from
          # Add 1 day to the local time candidate, then convert back to UTC
          candidate = (candidate_local + 1.day).to_utc
        end

        candidate
      end

      # Parse time string in various formats: "9AM", "9:00 AM", "9:00", "21:00", etc.
      private def self.parse_time_string(time_str : String) : Tuple(Int32, Int32)
        normalized = time_str.upcase.strip

        # Handle "9AM" or "9 PM" format (no colon)
        if normalized =~ /^(\d{1,2})\s*(AM|PM)?$/
          hour = adjust_hour_for_meridiem($1.to_i, $2)
          return {hour, 0}
        end

        # Handle "9:30 AM" or "9:30" format
        if normalized =~ /^(\d{1,2}):(\d{2})\s*(AM|PM)?$/
          hour = adjust_hour_for_meridiem($1.to_i, $3)
          minute = $2.to_i
          return {hour, minute}
        end

        raise ArgumentError.new("Invalid time format: #{time_str}")
      end

      # Adjust hour based on AM/PM meridiem
      private def self.adjust_hour_for_meridiem(hour : Int32, meridiem : String?) : Int32
        if meridiem == "PM" && hour != 12
          hour += 12
        elsif meridiem == "AM" && hour == 12
          hour = 0
        end
        hour
      end

      # Validate an interval string without throwing
      def self.valid?(interval : String) : Bool
        normalized = interval.downcase.strip

        # Check for "daily at HH:MM" format
        if normalized =~ /^daily\s+at\s+(.+)$/
          time_str = $1.strip
          begin
            parse_time_string(time_str)
            return true
          rescue
            return false
          end
        end

        parse(interval)
        true
      rescue
        false
      end
    end
  end
end
