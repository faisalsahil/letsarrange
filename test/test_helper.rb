require "codeclimate-test-reporter"
require 'database_cleaner'

CodeClimate::TestReporter.start

ENV["RAILS_ENV"] ||= "test"

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'capybara/rails'
require "mocha/setup"

Dir[Rails.root.join("test/helpers/test_helpers.rb")].each { |f| require f }

class ActiveSupport::TestCase
  include TestHelpers
  ActiveRecord::Migration.check_pending!

  self.use_transactional_fixtures = true
end

class ActionDispatch::IntegrationTest
  include Capybara::DSL
  self.use_transactional_fixtures = false

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
    TwilioNumber.load_twilio_numbers
    Capybara.current_session.driver.browser.manage.delete_all_cookies
  end
end

DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean
TwilioNumber.load_twilio_numbers