# frozen_string_literal: true

class PhoneParserService
  COUNTRY_CODE_REGEX = /\A\+\d{1,3}\d+\z/

  attr_reader :raw, :phone

  def initialize(raw_phone)
    @raw = raw_phone.to_s.strip
    @phone = Phonelib.parse(@raw)
  end

  def valid?
    country_code? && phone.valid?
  end

  def country_code?
    raw.match?(COUNTRY_CODE_REGEX)
  end

  def country_code
    return unless valid?

    "+#{phone.country_code}"
  end

  def national_number
    return unless valid?

    phone.national_number
  end

  def e164
    return unless valid?

    phone.e164
  end

  def to_h
    return {} unless valid?

    {
      country_code: country_code,
      national_number: national_number,
      e164: e164
    }
  end
end
