# frozen_string_literal: true

require 'bundler'
Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

# Load Spree extension rake tasks
begin
  require 'spree/testing_support/extension_rake'
rescue LoadError => e
  warn "Could not load spree/testing_support/extension_rake: #{e.message}"
end

desc 'Generate test dummy app'
task test_app: :environment do
  # Auto-detect gem name from gemspec
  ENV['LIB_NAME'] = 'spree/spl'

  Rake::Task['extension:test_app'].invoke
end

task default: :spec
