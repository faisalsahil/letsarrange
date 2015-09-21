source 'https://rubygems.org'
ruby '2.0.0'

gem 'rails', '4.0.3'
gem 'mysql2'
gem 'sass-rails', '~> 4.0.0'
gem 'bootstrap-sass', '~> 3.1.1'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jbuilder', '~> 1.2'
gem 'figaro'
gem 'devise'
gem 'devise-async'
gem 'simple_form'
gem 'pg'
gem 'postmark-rails'
gem 'phony'
gem 'paloma'
gem 'cocoon'
gem 'inherited_resources'
gem 'ransack'
gem 'twilio-ruby'
gem 'delayed_job_active_record'
gem 'daemons'
gem "workless", "~> 1.2.3"
gem 'detect_timezone_rails'
gem 'time_difference'
gem 'email_reply_parser', '~> 0.5.5'
gem "timecop"
gem 'rack-zippy'
# see activeadmin install on rails 4 => http://stackoverflow.com/questions/16426398/active-admin-install-with-rails-4/16805376#16805376
gem 'activeadmin', github: 'gregbell/active_admin'

group :production do
  gem 'newrelic_rpm', "~> 3.7.3.204"
  gem 'unicorn'
  gem 'rails_12factor'
end

group :test do
	gem 'shoulda'
	gem 'capybara'
	gem 'mocha'
  gem "codeclimate-test-reporter", require: nil
  gem 'selenium-webdriver'
  gem 'database_cleaner', require: false
end

group :development, :test do
	gem 'sextant', git: "git://github.com/schneems/sextant.git"
	gem 'rest-client'
  gem 'quiet_assets'
  gem 'letter_opener', '~> 1.2.0'
  gem 'debugger', require: ENV['USER'] != 'pablo' && 'debugger'
end

gem 'pry-rails', group: :development