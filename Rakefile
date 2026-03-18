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

desc 'Generate test dummy app and prepare DB (install migrations + migrate)'
task :test_app do
  ENV['LIB_NAME'] = 'spree/spl'
  ENV['RAILS_ENV'] ||= 'test'

  # 1. generate/refresh dummy app
  Rake::Task['extension:test_app'].invoke

  # 2. run install+migrate inside dummy app
  dummy_path =
    if ENV['DUMMY_PATH']
      File.expand_path(ENV['DUMMY_PATH'])
    else
      File.expand_path('spec/dummy', __dir__) # change if dummy lives elsewhere
    end


  # 3. copy migrations from gem only - this avoids duplicated migrations
  engine_root = Gem.loaded_specs['spree-spl'].full_gem_path
  source = File.join(engine_root, 'db/migrate')
  target = File.join(dummy_path, 'db/migrate')

  Dir.glob("#{source}/*.rb").each do |file|
    FileUtils.cp(file, target)
  end

  # 4. run migrations
  Dir.chdir(dummy_path) do
    ENV['RAILS_ENV'] = 'test'

    require File.expand_path('config/application', dummy_path)
    Rails.application.load_tasks

    Rake::Task['db:migrate'].reenable
    Rake::Task['db:migrate'].invoke
  end
end


task default: :spec
