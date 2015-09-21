require File.expand_path('../boot', __FILE__)

require 'rails/all'
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)



module LetsArrange
  class Application < Rails::Application
    config.autoload_paths += %W(#{config.root}/app/services)
    config.autoload_paths << "#{ config.root }/lib"

    require "#{config.root}/app/exceptions/exceptions.rb"

    config.middleware.use Rack::Deflater

    config.assets.precompile += %w( theme/cover.css )
    config.assets.precompile += %w[admin/active_admin.css admin/active_admin.js]

    config.action_mailer.delivery_method   = :postmark
    config.action_mailer.postmark_settings = { :api_key => ENV['POSTMARK_API_KEY'] }

    config.i18n.enforce_available_locales = true
  end

  def self.rake?
    !!@rake
  end

  def self.rake=(value)
    @rake = !!value
  end
end
