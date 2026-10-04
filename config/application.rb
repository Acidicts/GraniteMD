require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Granitemd
  # Deployments spell the app's address inconsistently: a bare host
  # (`granitemd.com`), a full URL (`https://granitemd.com/`), or a URL with a
  # path. Host authorization compares `config.hosts` literally against the
  # `Host`/`X-Forwarded-Host` headers, so a scheme or path makes every request
  # fail the check. Normalise once, here, and reuse it everywhere a host is
  # needed.
  def self.normalize_host(value)
    value.to_s.sub(%r{\A[a-z][a-z0-9+.-]*://}i, "").split("/").first.to_s.strip.presence
  end

  def self.app_host(env_key: "APP_HOST", default: "granitemd.local")
    normalize_host(ENV[env_key]) || default
  end

  # Reads host lists from the given env keys, accepting a JSON array
  # (`["a.com", "b.com"]`), a single JSON string, or a comma/space separated
  # list, and normalises every entry.
  def self.hosts_from_env(*env_keys)
    env_keys.filter_map { |key| ENV[key].presence }
            .flat_map { |value| split_host_list(value) }
            .filter_map { |host| normalize_host(host) }
            .uniq
  end

  def self.split_host_list(value)
    parsed = begin
      JSON.parse(value)
    rescue JSON::ParserError
      nil
    end

    case parsed
    when nil then value.split(/[\s,]+/)
    when String then [ parsed ]
    when Array then parsed.grep(String)
    else []
    end
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
    config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
    config.active_record.encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]

    config.active_record.encryption.support_unencrypted_data = true
    config.active_record.encryption.extend_queries = true

    config.active_storage.variant_processor = :vips

    config.hosts << Granitemd.app_host(env_key: "APP_URL", default: "localhost")

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    # config.generators do |g|
    config.generators do |g|
      g.test_framework :rspec,
                       fixtures: false,
                       view_specs: false,
                       helper_specs: false,
                       routing_specs: false
      g.factory_bot suffix: "factory"  # only if using factory_bot_rails
    end
    config.generators.system_tests = nil
  end
end
