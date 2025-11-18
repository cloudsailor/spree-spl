# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in spree-spl.gemspec
gemspec

gem 'byebug'
gem 'rake', '~> 13.0'
group :development, :test do
  gem 'brakeman'
  gem 'rubocop', '~> 1.79', '>= 1.79.2'
  gem 'rubocop-rails', '~> 2.33', '>= 2.33.3'
  gem 'rubocop-rails-omakase'
  gem 'sqlite3', '>= 2.0'
end

group :test do
  gem 'abbrev'
  gem 'factory_bot_rails'
  gem 'ffaker'
  gem 'observer'
  gem 'spree', '< 5.0'
  gem 'spree_backend', '< 5.0.0'
end
