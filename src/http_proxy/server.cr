require "http"
require "log"
require "../config/loader"
require "../landlock_socket"
require "./whitelist_prompt"

module HttpProxy
  Log = ::Log.for("crybot.http_proxy")

  # HTTP/HTTPS proxy server for tool access control
  #
  # Listens on localhost:3004
  # Checks domain whitelist
  # Prompts user via rofi for non-whitelisted domains
  # Forwards allowed requests to upstream
  # Logs all access attempts

  class Server
    # Request and Response structures
    struct ProxyRequest
      property method : String
      property path : String
      property headers : Hash(String, String)
      property body : String?
      property domain : String?

      def initialize(@method = "GET", @path = "/", @headers = {} of String => String, @body = nil, @domain = nil)
      end
    end

    struct ProxyConfig
      property enabled : Bool = false
      property host : String = "127.0.0.1"
      property port : Int32 = 3004
      property domain_whitelist : Array(String) = [] of String
      property log_file : String = "~/.crybot/logs/proxy_access.log"
    end

    # Access log entry
    struct AccessLog
      property timestamp : String
      property domain : String
      property action : String
      property details : String?

      def initialize(@timestamp = Time.local.to_s("%Y-%m-%d %H:%M:%S"), @domain = "", @action = "", @details = "")
      end
    end

    @@config : ProxyConfig?
    @@access_log : Array(AccessLog) = [] of AccessLog
    @@server : HTTP::Server?

    def self.start : Nil
      config = Config::Loader.load
      proxy_config = config.proxy?

      unless proxy_config
        Log.info { "HTTP proxy not enabled, starting server anyway for testing" }
      end

      @@config = proxy_config || ProxyConfig.new
      @@access_log = [] of AccessLog

      # Create HTTP server
      @@server = HTTP::Server.new(@@config.host, @@config.port) do |context|
        handle_request(context, proxy_config)
      end

      Log.info { "Proxy server started on http://#{@config.host}:#{@config.port}" }
      Log.info { "Domain whitelist: #{@config.domain_whitelist.join(", ")}" }
      Log.info { "Access log: #{@config.log_file}" }
    end

    def self.stop : Nil
      if server = @@server
        server.close
        Log.info { "Proxy server stopped" }
      end
    end

    # Handle incoming HTTP request
    private def self.handle_request(context : HTTP::Server::Context, config : ProxyConfig) : Nil
      request = parse_request(context)

      # Extract domain from request
      request_domain = extract_domain(request)

      # Check whitelist
      if config.domain_whitelist.includes?(request_domain)
        # Whitelisted domain - allow through
        log_access(request_domain, "allow", "Whitelisted")
        forward_request(context, request)
      else
        # Non-whitelisted domain - prompt user
        prompt_user_and_handle(context, request, request_domain, config)
      end
    end

    # Parse HTTP request from context
    private def self.parse_request(context : HTTP::Server::Context) : ProxyRequest
      method = context.request.method || "GET"
      path = context.request.path || "/"
      headers = context.request.headers.try(&.to_h) || {} of String => String
      body = context.request.body.try(&.as_s)

      # Extract Host header for domain checking
      domain = if host_header = headers["Host"]?
               URI.parse(host_header).hostname
             else
               nil
        end

      ProxyRequest.new(method, path, headers, body, domain)
    end

    # Extract domain from Host header or URL
    private def self.extract_domain(request : ProxyRequest) : String
      # Check Host header first
      if domain = request.domain
        return domain
      end

      # Try to extract from request path if URL
      if request.path.size > 1 && request.path.starts_with?("/")
        uri = URI.parse("http://dummy#{request.path}")
        return uri.hostname || ""
      end

      ""

      # Log access attempt
      private def self.log_access(domain : String, action : String, details : String = "") : Nil
        log_entry = AccessLog.new(domain, action, details)

        @@access_log << log_entry
        Log.info { "[#{log_entry.action}] #{log_entry.domain}: #{log_entry.details}" }

        # Also write to file if configured
        if @@config.try(&.log_file)
          begin
            File.open(@@config.not_nil!.log_file, "a") do |file|
              @@access_log.each do |entry|
                file.puts("#{entry.timestamp} #{entry.action} #{entry.domain} - #{entry.details}")
              end
            end
          rescue e : Exception
            Log.error(exception: e) { "Failed to write access log: #{e.message}" }
          end
      end

    # Prompt user via rofi and handle decision
    private def self.prompt_user_and_handle(context : HTTP::Server::Context, request : ProxyRequest, request_domain : String, config : ProxyConfig) : Nil
      # Show rofi prompt
      result = WhitelistPrompt.prompt(request_domain)

      case result
      when :allow
        # Whitelisted - allow through and log
        log_access(request_domain, "allow", "Whitelisted")
        forward_request(context, request)

      when :allow_once
        # Allow once - allow through but don't save to whitelist
        log_access(request_domain, "allow_once", "Session-only allowance")
        forward_request(context, request)

      when :deny
        # Denied - return 403
        log_access(request_domain, "deny", "User denied")
        context.response.status_code = 403
        context.response.puts("Access denied")
        context.response.close

      else
        # Unexpected response - log and deny
        log_access(request_domain, "deny", "Invalid response (#{result})")
        context.response.status_code = 403
        context.response.puts("Access denied")
        context.response.close
      end
    end

    # Forward request to upstream
    private def self.forward_request(context : HTTP::Server::Context, request : ProxyRequest) : Nil
      # Build upstream URL
      upstream_url = "http://#{request.domain}#{request.path}"
      if request.query = request.query
        upstream_url += "?#{request.query}"
      upstream_url = request.headers.to_h.reduce(upstream_url) do |url, |key, value|
        "#{url}&#{key}=#{URI.encode_component(value)}"
      end

      # Create upstream request
      begin
        upstream_response = HTTP::Client.get(upstream_url)

        # Copy response headers to client response
        upstream_response.headers.each do |key, value|
          context.response.headers[key] = value
        end

        # Copy response body
        context.response.puts(upstream_response.body)
        context.response.close

        Log.debug { "Forwarded: #{request.method} #{request.path} -> #{upstream_response.status_code}" }
      rescue e : Exception
        Log.error(exception: e) { "Proxy error: #{e.message}" }
        context.response.status_code = 500
        context.response.puts("Proxy error: #{e.message}")
        context.response.close
      end
    end
  end
end
