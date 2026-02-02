require "http"
require "json"
require "html"
require "./base"

module Crybot
  module Agent
    module Tools
      class WebSearchTool < Tool
        def name : String
          "web_search"
        end

        def description : String
          "Search the web using Brave Search API. Returns search results with titles, URLs, and snippets."
        end

        def parameters : Hash(String, JSON::Any)
          {
            "type"       => JSON::Any.new("object"),
            "properties" => JSON::Any.new({
              "query" => JSON::Any.new({
                "type"        => JSON::Any.new("string"),
                "description" => JSON::Any.new("The search query"),
              }),
              "max_results" => JSON::Any.new({
                "type"        => JSON::Any.new("integer"),
                "description" => JSON::Any.new("Maximum number of results to return (default: 5)"),
              }),
            }),
            "required" => JSON::Any.new(["query"].map { |string| JSON::Any.new(string) }),
          }
        end

        def execute(args : Hash(String, JSON::Any)) : String
          query = get_string_arg(args, "query")
          max_results = get_int_arg(args, "max_results", 5)

          return "Error: query is required" if query.empty?

          # Get API key from config
          api_key = get_search_api_key
          if api_key.empty?
            return "Error: Web search API key not configured. Add it to config.yml under tools.web.search.api_key"
          end

          begin
            url = "https://api.search.brave.com/res/v1/web/search"
            headers = HTTP::Headers{
              "Accept"               => "application/json",
              "X-Subscription-Token" => api_key,
            }

            params = HTTP::Params.encode({
              "q"     => query,
              "count" => max_results.to_s,
            })

            response = HTTP::Client.get("#{url}?#{params}", headers)

            unless response.success?
              return "Error: Search API failed: #{response.status_code}"
            end

            parse_search_results(response.body)
          rescue e : Exception
            "Error: #{e.message}"
          end
        end

        private def get_search_api_key : String
          config = Crybot::Config::Loader.load
          config.tools.web.search.api_key
        rescue
          ""
        end

        private def parse_search_results(body : String) : String
          json = JSON.parse(body)
          results = [] of String

          web_value = json["web"]?
          results_value = web_value ? web_value["results"]? : nil
          if results_value && results_value.as_a?
            results_value.as_a.each do |result|
              title = result["title"].as_s
              url = result["url"].as_s
              snippet = result["description"]?.try(&.as_s) || ""

              results << "#{title}\n  #{url}\n  #{snippet}"
            end
          end

          results.empty? ? "No results found" : results.join("\n\n")
        end
      end

      class WebFetchTool < Tool
        def name : String
          "web_fetch"
        end

        def description : String
          "Fetch and read a web page. Returns the page content with HTML stripped."
        end

        def parameters : Hash(String, JSON::Any)
          {
            "type"       => JSON::Any.new("object"),
            "properties" => JSON::Any.new({
              "url" => JSON::Any.new({
                "type"        => JSON::Any.new("string"),
                "description" => JSON::Any.new("The URL to fetch"),
              }),
            }),
            "required" => JSON::Any.new(["url"].map { |string| JSON::Any.new(string) }),
          }
        end

        def execute(args : Hash(String, JSON::Any)) : String
          url = get_string_arg(args, "url")

          return "Error: url is required" if url.empty?

          begin
            response = HTTP::Client.get(url)

            unless response.success?
              return "Error: Failed to fetch URL: #{response.status_code}"
            end

            # Strip HTML tags
            content = response.body
            text_content = strip_html(content)

            # Limit output size
            if text_content.size > 10_000
              text_content = text_content[0, 10_000] + "\n\n... (truncated)"
            end

            text_content
          rescue e : Exception
            "Error: #{e.message}"
          end
        end

        private def strip_html(html : String) : String
          # Simple HTML tag stripping
          result = html.gsub(/<script[^>]*>.*?<\/script>/m, "")
          result = result.gsub(/<style[^>]*>.*?<\/style>/m, "")
          result = result.gsub(/<[^>]+>/, "")
          result = result.gsub(/&nbsp;/i, " ")
          result = result.gsub(/&amp;/i, "&")
          result = result.gsub(/&lt;/i, "<")
          result = result.gsub(/&gt;/i, ">")
          result = result.gsub(/&quot;/i, "\"")
          result = result.gsub(/&#39;/i, "'")
          result = result.gsub(/\s+/, " ").strip
          result
        end
      end
    end
  end
end
