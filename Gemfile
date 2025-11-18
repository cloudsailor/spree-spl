# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in spree-spl.gemspec
gemspec

gem 'rake', '~> 13.0'
gem 'byebug'

group :development, :test do
  gem 'brakeman'
  gem 'rubocop', '~> 1.79', '>= 1.79.2'
  gem 'rubocop-rails', '~> 2.33', '>= 2.33.3'
  gem 'sqlite3', '>= 2.0'
end

group :test do
  gem 'spree', '< 5.0'
  gem 'spree_backend', '< 5.0.0'
  gem 'factory_bot_rails'
  gem 'ffaker'
  gem 'observer'
  gem 'abbrev'
end
