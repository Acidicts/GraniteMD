require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Add Redis cache store. Deliberately no `ssl_params`: the generator default
  # sets VERIFY_NONE, which silently disables certificate validation on the tier
  # holding the rate-limit counters. Pass a CA bundle via REDIS_URL/REDIS_SSL_* if
  # the cache is reached over TLS.
  config.cache_store = :redis_cache_store, {
    url: ENV.fetch("REDIS_URL"),
    pool: {
      size: ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i,
      timeout: 5
    }
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks. Leaving this
  # empty lets any Host header through, which in turn lets a spoofed Host
  # poison any absolute URL the app generates or redirects to.
  app_host = Granitemd.app_host(default: "granitemd.com")
  extra_hosts = Granitemd.hosts_from_env("ALLOWED_HOSTS", "ALLOWED_HOST")
  config.hosts = ([ app_host ] + extra_hosts).uniq.flat_map { |host| [ host, ".#{host}" ] }

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Email delivery over SMTP, configured entirely from the environment.
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: app_host, protocol: "https" }
  smtp_settings = {
    address: ENV["SMTP_HOST"].presence || "localhost",
    port: ENV["SMTP_PORT"].presence&.to_i || 587,
    domain: ENV["SMTP_DOMAIN"].presence || app_host,
    enable_starttls_auto: ENV.fetch("SMTP_STARTTLS", "true") == "true",
    user_name: ENV["SMTP_USER"].presence,
    password: ENV["SMTP_PASSWORD"].presence
  }.compact
  smtp_settings[:authentication] = ENV.fetch("SMTP_AUTHENTICATION", "plain").to_sym if smtp_settings[:user_name]

  config.action_mailer.smtp_settings = smtp_settings
end
