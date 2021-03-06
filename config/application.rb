# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'
# require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Geyser0
  class Application < Rails::Application
    Dotenv::Railtie.load

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    %w(lib app/lib app/commands).each do |folder|
      config.autoload_paths << Rails.root.join(folder)
    end

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.helper false
    end

    config.i18n.available_locales = %i(en ru)

    # http://batsov.com/articles/2012/09/12/setting-up-fallback-locale-s-in-rails-3/
  end
end
