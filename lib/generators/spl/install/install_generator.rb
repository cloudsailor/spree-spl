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
    end
  end
end
