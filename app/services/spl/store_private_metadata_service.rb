# frozen_string_literal: true

module Spl
  module StorePrivateMetadataService
    module_function

    def all(store)
      (store&.private_metadata || {}).deep_dup
    end

    def fetch(store, key, default: nil)
      all(store).fetch(key.to_s, default)
    end
  end
end
