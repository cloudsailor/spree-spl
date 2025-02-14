# frozen_string_literal: true

module Spree
  module Spl
    class Engine < Rails::Engine
      isolate_namespace Spree::Spl
    end
  end
end
