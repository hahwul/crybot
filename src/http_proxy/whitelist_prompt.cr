require "log"
require "process"
require "../config/loader"
require "../landlock_socket"

module HttpProxy
  Log = ::Log.for("crybot.http_proxy")

  # Rofi prompt handler for domain access decisions
  module WhitelistPrompt
    # Prompt user for domain access decision via rofi
    #
    # Returns: :allow, :deny, :allow_once

    def self.prompt(domain : String) : Symbol
      config = Config::Loader.load

      # Build rofi prompt message
      message = "🔒 HTTP Proxy - Domain Access Request\n\n"
      message += "Domain: #{domain}\n\n"
      message += "Allow this domain for current and future requests?\n\n"
      message += "Options:\n"
      message += "  Allow - Allow this domain (add to whitelist)\n"
      message += "  Once Only - Allow for this session only\n"
      message += "  Deny - Block this domain request\n\n"

      # Show rofi prompt
      result = IO::Memory.new

      status = Process.run(
        "rofi",
        ["-dmenu", "-mesg", message, "-i", "-p", "Allow,Deny", "Once Only"],
        input: IO::Memory.new(""),
        output: result
      )

      unless status.success?
        Log.error { "Rofi prompt failed" }
        return :deny
      end

      choice = result.to_s.strip

      case choice
      when "Allow"
        handle_allow(domain)
      when "Once Only"
        handle_allow_once(domain)
      when "Deny"
        handle_deny(domain)
      else
        Log.warn { "Unexpected rofi choice: #{choice}" }
        :deny
      end
    end

    private def self.handle_allow(domain : String) : Nil
      # Add to whitelist and allow
      proxy_config = Config::Loader.load
      whitelist = proxy_config.proxy?.try(&.domain_whitelist) || [] of String

      unless whitelist.includes?(domain)
        whitelist << domain
        Log.info { "Added #{domain} to whitelist" }

        # Update config
        updated_config = if proxy_config.proxy?
                           proxy_config.proxy.not_nil!.merge(ProxyConfig.from(domain_whitelist: whitelist))
                         else
                           Config::ProxyConfig.new(
                             enabled: true,
                             host: proxy_config.proxy.not_nil!.host,
                             port: proxy_config.proxy.not_nil!.port,
                             domain_whitelist: whitelist,
                             log_file: proxy_config.proxy.not_nil!.log_file
                           )
                         end

        Config::Loader.save_config(updated_config)
      end

      Log.info { "Allowed #{domain} - whitelisted now" }
    end

    private def self.handle_allow_once(domain : String) : Nil
      # Allow for this session only (no config change)
      Log.info { "Allowed #{domain} for this session only" }
    end

    private def self.handle_deny(domain : String) : Nil
      Log.warn { "Denied access to #{domain}" }

      # Request to stop proxy server to update config
      if proxy_config = Config::Loader.load.proxy?
        LandlockSocket.send_reload_signal
      end
    end
  end
end
