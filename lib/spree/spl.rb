# frozen_string_literal: true

require "spree/spl/version"
require "spree/spl/engine"

ENGINE_PATH = File.expand_path('../../lib/spree/spl/engine', __FILE__)

require 'rails/all'
require 'spree_core'
require 'spree_api'

require_relative "spl/version"

module Spree
  module Spl
    # Your code goes here...
  end
end
