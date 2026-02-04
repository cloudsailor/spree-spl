# frozen_string_literal: true

module Spl
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Install SPL Stimulus controller'

      def copy_stimulus_controller
        destination = 'app/javascript/controllers/login_spl_controller.js'

        if File.exist?(destination)
          say_status :skip, "#{destination} already exists", :yellow
        else
          copy_file 'login_spl_controller.js', destination
          say_status :create, destination, :green
        end
      end

      def ensure_controllers_autoload
        controllers_index = 'app/javascript/controllers/index.js'

        unless File.exist?(controllers_index)
          say_status :warning, 'Stimulus controllers index.js not found', :yellow
          return
        end

        say_status :info, 'Stimulus controllers are auto-loaded', :blue
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=spree_spl'
      end

      def run_migrations
        run_migrations = options[:migrate] || ['', 'y', 'Y'].include?(ask('Would you like to run the migrations now? [Y/n]'))
        if run_migrations
          run 'bin/rails db:migrate'
        else
          Rails.logger.debug 'Skipping rails db:migrate, don\'t forget to run it!'
        end
      end
    end
  end
end
