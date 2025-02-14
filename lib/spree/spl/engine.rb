# require_dependency 'spree/spl'

module Spree
  module Spl
    class Engine < Rails::Engine
      isolate_namespace Spree::Spl
    end
  end
end
