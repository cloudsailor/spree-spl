# frozen_string_literal: true

module Spl
  class ErrorPayloadParser
    def self.parse(message)
      str = message.to_s.strip
      return nil unless str.start_with?('{') && str.end_with?('}')

      inner = str[1..-2]
      result = {}
      inner.split(/,\s+/).each do |pair|
        k, v = pair.split(/\s*=>\s*/, 2)
        next unless k && v

        key = unquote(k.strip)
        value = parse_value(v.strip)
        result[key] = value
      end
      result
    rescue StandardError
      nil
    end

    def self.parse_value(v)
      return nil if v == 'nil'
      return unquote(v) if v.start_with?('"') && v.end_with?('"')

      v
    end

    def self.unquote(s)
      s = s.strip
      s = s[1..-2] if s.start_with?('"') && s.end_with?('"')
      s.gsub('\"', '"').gsub('\\\\', '\\')
    end

    private_class_method :parse_value, :unquote
  end
end
