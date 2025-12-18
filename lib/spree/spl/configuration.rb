module Spree
  module Spl
    class Configuration
      attr_accessor :error_reporter

      def initialize
        @error_reporter = ->(message, extra = {}) { Rails.logger.warn("[SPL] #{message} #{extra.inspect}") }
      end
    end

    def self.config = (@config ||= Configuration.new)
    def self.configure = yield(config)

    def self.report_error(message, extra = {})
      config.error_reporter&.call(message, extra)
    rescue => ex
      Rails.logger.error("[SPL] error_reporter failed: #{ex.class}: #{ex.message}")
    end
  end
end
