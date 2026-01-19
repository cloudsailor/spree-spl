# frozen_string_literal: true

module Spl
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Install SPL Stimulus controller'

      def copy_stimulus_controller
        copy_file('login_spl_controller.js', 'app/javascript/controllers/login_spl_controller.js')
      end

      def ensure_controllers_autoload
        controllers_index = 'app/javascript/controllers/index.js'

        return unless File.exist?(controllers_index)

        content = File.read(controllers_index)

        return if content.include?('login_spl')

        say_status :info, 'Stimulus controllers are auto-loaded, nothing to register', :blue
      end
    end
  end
end
