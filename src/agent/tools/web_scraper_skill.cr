require "../tools/base"
require "../../config/loader"
require "file_utils"
require "http/client"

module Crybot
  module Agent
    module Tools
      # Tool for creating web scraping skills (supports HTTP and MCP/Playwright)
      class CreateWebScraperSkillTool < Tool
        def name : String
          "create_web_scraper_skill"
        end

        def description : String
          "Creates a new skill for scraping content from websites. Supports both simple HTTP fetching and MCP/Playwright for JavaScript-heavy sites. The skill will fetch from URLs and extract headlines, links, summaries, etc."
        end

        def parameters : Hash(String, JSON::Any)
          {
            "type" => JSON::Any.new("object"),
            "properties" => JSON::Any.new({
              "name" => JSON::Any.new({
                "type"        => JSON::Any.new("string"),
                "description" => JSON::Any.new("The skill name (e.g., 'tech_news', 'hacker_news')"),
              }),
              "description" => JSON::Any.new({
                "type"        => JSON::Any.new("string"),
                "description" => JSON::Any.new("What this skill does (e.g., 'Aggregates tech news from Hacker News')"),
              }),
              "urls" => JSON::Any.new({
                "type"        => JSON::Any.new("array"),
                "description" => JSON::Any.new("Array of URLs to scrape"),
                "items"       => JSON::Any.new({"type" => JSON::Any.new("string")}),
              }),
              "fetch_method" => JSON::Any.new({
                "type"        => JSON::Any.new("string"),
                "description" => JSON::Any.new("How to fetch: 'http' for simple sites, 'mcp_playwright' for JavaScript-heavy sites (default: 'http')"),
              }),
              "mcp_server" => JSON::Any.new({
                "type"        => JSON::Any.new("string"),
                "description" => JSON::Any.new("MCP server name for Playwright (default: 'playwright')"),
              }),
              "selector" => JSON::Any.new({
                "type"        => JSON::Any.new("string"),
                "description" => JSON::Any.new("CSS selector to extract content (e.g., 'a.story-link', 'article.title') - will be auto-detected if not specified"),
              }),
              "extract" => JSON::Any.new({
                "type"        => JSON::Any.new("string"),
                "description" => JSON::Any.new("What to extract from each matched element: 'text', 'html', 'attr:href', 'attr:title', etc."),
              }),
            }),
            "required" => JSON::Any.new([JSON::Any.new("name"), JSON::Any.new("description"), JSON::Any.new("urls")] of JSON::Any),
          }
        end

        def execute(args : Hash(String, JSON::Any)) : String
          name = args["name"]?.try(&.as_s) || ""
          description = args["description"]?.try(&.as_s) || ""
          fetch_method = args["fetch_method"]?.try(&.as_s) || "http"
          mcp_server = args["mcp_server"]?.try(&.as_s) || "playwright"
          selector = args["selector"]?.try(&.as_s) || ""
          extract = args["extract"]?.try(&.as_s) || "text"

          urls_arg = args["urls"]?
          return "Error: 'urls' parameter is required" if urls_arg.nil?

          # Parse URLs array
          urls = [] of String
          if urls_arr = urls_arg.as_a?
            urls_arr.each do |url|
              urls << url.as_s if url.as_s?
            end
          end

          return "Error: 'name' parameter is required" if name.empty?
          return "Error: 'description' parameter is required" if description.empty?
          return "Error: At least one valid URL is required" if urls.empty?

          # Sanitize skill name
          name = name.downcase.gsub(/[^a-z0-9_\-]/, "_")

          # Create skill directory
          skills_dir = Config::Loader.skills_dir
          Dir.mkdir_p(skills_dir) unless Dir.exists?(skills_dir)

          skill_dir = skills_dir / name

          if Dir.exists?(skill_dir)
            return "Error: Skill '#{name}' already exists. Please choose a different name."
          end

          Dir.mkdir(skill_dir)

          # Generate tool name
          tool_name = "#{name}_scraper"

          # Detect if we should use Playwright
          use_playwright = fetch_method == "mcp_playwright" || should_use_playwright?(urls)

          # Generate skill.yml
          if use_playwright
            generate_playwright_skill(skill_dir, name, tool_name, description, urls, mcp_server, selector, extract)
            method_used = "MCP Playwright (for JavaScript-rendered content)"
          else
            generate_http_skill(skill_dir, name, tool_name, description, urls, selector, extract)
            method_used = "HTTP (simple fetching)"
          end

          # Generate SKILL.md
          generate_skill_md(skill_dir, name, description, urls, use_playwright, mcp_server, selector, extract)

          urls_list = urls.map { |u| "  - #{u}" }.join("\n")

          "Successfully created web scraper skill '#{name}'!\n\n" \
          "Skill location: #{skill_dir}\n" \
          "Tool name: #{tool_name}\n" \
          "Method: #{method_used}\n\n" \
          "Sources:\n#{urls_list}\n\n" \
          "Next steps:\n" \
          "1. Review skill.yml in the web UI (Skills section)\n" \
          "2. You may need to adjust the CSS selector based on the site structure\n" \
          "3. Click 'Reload Skills' to load the new skill\n" \
          "4. Ask me to use the #{tool_name} tool!\n\n" \
          "Usage:\n" \
          "- \"Get the latest #{name}\"\n" \
          "- \"Scrape #{name} headlines\"\n" \
          "- \"What's on #{urls.first}?\""
        rescue e : Exception
          "Error creating web scraper skill: #{e.message} #{e.backtrace?.try(&.first).try { |s| "\n  #{s}" } || ""}"
        end

        private def should_use_playwright?(urls : Array(String)) : Bool
          # Check if any URL is likely to be a JS-heavy site
          js_heavy_patterns = [
            /twitter\.com/,
            /x\.com/,
            /facebook\.com/,
            /instagram\.com/,
            /youtube\.com/,
            /reddit\.com/,
            /news\.ycombinator\.com/,
            /techcrunch\.com/,
            /github\.com/,
          ]

          urls.any? { |url| js_heavy_patterns.any? { |pattern| url =~ pattern } }
        end

        private def generate_playwright_skill(dir : Path, name : String, tool_name : String, description : String, urls : Array(String), mcp_server : String, selector : String, extract : String) : Nil
          # Generate CSS selector based on common patterns if not provided
          css_selector = selector.empty? ? suggest_selector(urls[0]) : selector

          urls_list = urls.map_with_index { |u, i| "      - \"{{url_#{i}}}\"" }.join("\n")

          skill_yml = <<-YAML
name: #{name}
version: 1.0.0
description: #{description} (uses MCP Playwright)

tool:
  name: #{tool_name}
  description: Scrape content from websites using Playwright (for JavaScript-rendered content)
  parameters:
    type: object
    properties:
      url:
        type: string
        description: The URL to scrape (defaults to first configured source)
      limit:
        type: string
        description: Maximum number of items to return (default: "5")
    required: []

execution:
  type: command
  command:
    command: crybot
    args:
      - "mcp"
      - "--server"
      - "#{mcp_server}"
      - "call"
      - "navigate"
      - "{{url}}"
    working_dir: null

note: |
  This skill uses MCP Playwright to scrape JavaScript-rendered content.

  The tool will:
  1. Navigate to the URL using Playwright
  2. Wait for the page to load
  3. Extract content using CSS selector: #{css_selector}
  4. Return the #{extract} from each matched element

  Configured sources:
#{urls_list}

  To extract different content, modify the skill to use different MCP calls:
  - 'navigate' - Go to a URL
  - 'snapshot' - Get page snapshot
  - 'click' - Click elements
  - 'fill' - Fill forms

  Common CSS selectors:
  - a.story-link - Hacker News story links
  - article.post-title - Blog post titles
  - h2.entry-title - Article headers
  - a[href*='/article/'] - Article links
YAML

          File.write(dir / "skill.yml", skill_yml)
        end

        private def generate_http_skill(dir : Path, name : String, tool_name : String, description : String, urls : Array(String), selector : String, extract : String) : Nil
          # For HTTP, we use web_fetch which can handle basic HTML
          css_selector = selector.empty? ? suggest_selector(urls[0]) : selector

          skill_yml = <<-YAML
name: #{name}
version: 1.0.0
description: #{description} (HTTP fetching)

tool:
  name: #{tool_name}
  description: Fetch and scrape content from websites
  parameters:
    type: object
    properties:
      url:
        type: string
        description: The URL to scrape (optional, uses configured source if not specified)
      limit:
        type: string
        description: Maximum number of items to return (default: "5")
    required: []

execution:
  type: http
  http:
    url: "{{url}}"
    method: GET
    response_format: |
      The page content has been fetched. Use CSS selector "#{css_selector}"
      to extract the "#{extract}" from matching elements.

      Raw content: {{content}}

note: |
  This skill uses HTTP fetching and then processes the HTML.

  The actual scraping is done by the agent using the CSS selector after fetching.

  CSS selector pattern: #{css_selector}
  Extraction method: #{extract}

  To customize:
  1. Test different CSS selectors using browser dev tools
  2. Adjust the 'extract' parameter (text, html, attr:href, etc.)
  3. For JavaScript-heavy sites, recreate this skill with fetch_method='mcp_playwright'

  Tips:
  - Use browser dev tools (F12) to inspect element structure
  - Test selectors in the console: document.querySelectorAll('your-selector')
  - Some sites may require specific headers or User-Agent
YAML

          File.write(dir / "skill.yml", skill_yml)
        end

        private def suggest_selector(url : String) : String
          # Suggest common CSS selectors based on the URL
          case url
          when /news\.ycombinator\.com/
            "a.storylink, .titleline > a"
          when /techcrunch\.com/
            "a.post-block__title__link"
          when /reddit\.com/
            "a.title, h3"
          when /twitter\.com/, /x\.com/
            "article[data-testid='tweet'] a"
          when /github\.com/
            "a[href*='/issues/'], a[href*='/pull/']"
          else
            "a, h1, h2, h3, article, .title, .post-title"
          end
        end

        private def generate_skill_md(dir : Path, name : String, description : String, urls : Array(String), use_playwright : Bool, mcp_server : String, selector : String, extract : String) : Nil
          urls_list = urls.map { |u| "- #{u}" }.join("\n  ")

          method_note = use_playwright ?
            "This skill uses **MCP Playwright** (#{mcp_server}) to scrape JavaScript-rendered content." :
            "This skill uses **HTTP fetching** for simple HTML sites."

          skill_md = <<-MD
# #{name.capitalize.gsub("_", " ")} Skill

#{description}

## Usage

This skill provides the `#{name}_scraper` tool to scrape content from websites.

## Sources

#{urls_list}

## Method

#{method_note}

## CSS Selector

The skill uses the CSS selector: `#{selector.empty? ? "auto-detected" : selector}`

To find the right selector:
1. Open the website in your browser
2. Press F12 to open Developer Tools
3. Use the element inspector to find the content you want
4. Right-click the element → Copy → Copy selector

## Usage Examples

- "Get the latest #{name}"
- "Scrape #{name} headlines"
- "What's on #{urls.first}?"
- "Extract titles from #{name}"

## Notes

- For JavaScript-heavy sites, the skill uses Playwright to render content
- You may need to adjust the CSS selector based on the site's structure
- Be respectful of rate limiting when scraping
MD

          File.write(dir / "SKILL.md", skill_md)
        end
      end
    end
  end
end
