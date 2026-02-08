require "json"

module Crybot
  module Approval
    REQUESTS_DIR = File.join(Path.home.to_s, ".crybot", "approval_requests")

    class Request
      include JSON::Serializable

      property id : String
      property path : String
      property created_at : String
      property status : String
      property modality : String
      property session_id : String?

      def initialize(@path : String, @modality : String, @session_id : String? = nil)
        @id = "#{Time.local.to_s("%Y%m%d%H%M%S")}-#{Random::Secure.hex(4)}"
        @created_at = Time.local.to_s
        @status = "pending"
      end

      def file_path : String
        File.join(REQUESTS_DIR, "#{@id}.json")
      end

      def save : Bool
        Dir.mkdir_p(REQUESTS_DIR) unless Dir.exists?(REQUESTS_DIR)
        File.write(file_path, to_json)
        true
      rescue
        false
      end

      def self.load(id : String) : Request?
        path = File.join(REQUESTS_DIR, "#{id}.json")
        return nil unless File.exists?(path)

        content = File.read(path)
        from_json(content)
      rescue
        nil
      end

      def self.all_pending : Array(Request)
        return [] of Request unless Dir.exists?(REQUESTS_DIR)

        Dir.children(REQUESTS_DIR)
          .select { |f| f.ends_with?(".json") }
          .compact_map do |filename|
            id = File.basename(filename, ".json")
            load(id)
          end
          .select { |r| r.status == "pending" }
      end
    end
  end
end
