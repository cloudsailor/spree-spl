# frozen_string_literal: true

require_relative 'lib/spree/spl/version'

Gem::Specification.new do |spec|
  spec.platform = Gem::Platform::RUBY
  spec.name = 'spree-spl'
  spec.version = Spree::Spl::VERSION
  spec.summary = 'Extension for Spree to allow to integrate with SpartaLoyalty'
  spec.description = 'Extension for Spree to allow to integrate with SpartaLoyalty'
  spec.homepage = 'https://github.com/cloudsailor/spree-spl'
  spec.required_ruby_version = '>= 3.3.0'
  spec.license = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = "https://github.com/cloudsailor/spree-spl/tree/#{spec.version}"
  spec.metadata['changelog_uri'] = "https://github.com/cloudsailor/spree-spl/releases/tag/#{spec.version}"

  spec.authors = ['nika-piotrowska']
  spec.email = ['support@cloudsailor.com']

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir['CHANGELOG', 'README.md', 'LICENSE', 'lib/**/*', 'app/**/*', 'config/**/*']
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency('deface')
  spec.add_dependency('faraday')
  spec.add_dependency('openssl')

  spree_version = ['~> 5.1', '>= 5.1.4']
  spec.add_dependency 'bigdecimal'
  spec.add_dependency 'rails', '~> 7.0'
  spec.add_dependency 'spree'
  spec.add_dependency 'spree_api', spree_version
  spec.add_dependency 'spree_auth_devise'
  spec.add_dependency 'spree_core', spree_version
  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end
