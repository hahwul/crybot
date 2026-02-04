require "json"

module Crybot
  module Agent
    # Parse and format JSON responses using template strings
    #
    # Supports extracting nested values from JSON responses
    # and formatting them with a template string.
    class ResponseParser
      # Parse a JSON response and format it using a template
      #
      # @param json_response The JSON response as a string
      # @param format_template The template string for formatting
      # @return The formatted response string
      def self.parse(json_response : String, format_template : String?) : String
        return json_response if format_template.nil? || format_template.empty?

        begin
          parsed = JSON.parse(json_response)
          context = json_any_to_hash(parsed)
          TemplateEngine.render(format_template, context)
        rescue e : JSON::ParseException
          # If JSON parsing fails, return the raw response
          json_response
        rescue e : Exception
          # If any other error occurs, return the raw response
          json_response
        end
      end

      # Convert JSON::Any to a Hash(String, JSON::Any) for template rendering
      private def self.json_any_to_hash(any : JSON::Any) : Hash(String, JSON::Any)
        case any.raw
        when Hash
          any.as_h
        when Array
          # For arrays, create a numbered index
          hash = {} of String => JSON::Any
          arr = any.as_a
          arr.each_with_index do |item, index|
            hash[index.to_s] = item
          end
          hash
        else
          # For primitives, wrap in a "value" key
          {"value" => any}
        end
      end

      # Extract a specific value from JSON using a path
      # e.g., "data.users.0.name" extracts the name of the first user
      def self.extract_value(json_response : String, path : String) : JSON::Any?
        parsed = JSON.parse(json_response)
        parts = path.split('.')
        current = parsed

        parts.each do |part|
          case current.raw
          when Hash
            hash = current.as_h
            current = hash[part]?
            return nil if current.nil?
          when Array
            index = part.to_i?
            if index
              arr = current.as_a
              current = arr[index]?
              return nil if current.nil?
            else
              return nil
            end
          else
            return nil
          end
        end

        current
      end
    end
  end
end
