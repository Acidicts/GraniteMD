require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Make code changes take effect immediately without server restart.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing.
  config.server_timing = true

  # Caching Configs
  config.action_controller.perform_caching = true
  config.action_controller.enable_fragment_cache_logging = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{2.days.to_i}" }

  config.cache_store = :redis_cache_store, {
    url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }
  }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Append comments with runtime information tags to SQL queries in logs.
  config.active_record.query_log_tags_enabled = true

  # Highlight code that triggered redirect in logs.
  config.action_dispatch.verbose_redirect_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true

  config.hosts << "3000--main--granitemd--acidicts.coder.bing-bong.uk"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Email delivery: real SMTP when SMTP_HOST is set, otherwise write files to tmp/mails.
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  if ENV["SMTP_HOST"].present?
    config.action_mailer.delivery_method = :smtp
    smtp_settings = {
      address: ENV["SMTP_HOST"],
      port: ENV["SMTP_PORT"].presence&.to_i || 587,
      domain: ENV["SMTP_DOMAIN"].presence || "localhost",
      enable_starttls_auto: ENV.fetch("SMTP_STARTTLS", "true") == "true",
      user_name: ENV["SMTP_USER"].presence,
      password: ENV["SMTP_PASSWORD"].presence
    }.compact
    smtp_settings[:authentication] = ENV.fetch("SMTP_AUTHENTICATION", "plain").to_sym if smtp_settings[:user_name]

    config.action_mailer.smtp_settings = smtp_settings
  else
    config.action_mailer.delivery_method = :file
    config.action_mailer.file_settings = { location: Rails.root.join("tmp", "mails") }
  end
end
