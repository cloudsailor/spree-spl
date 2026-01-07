# frozen_string_literal: true

class PhoneParserService
  attr_reader :phone

  def initialize(raw_phone)
    @phone = Phonelib.parse(raw_phone)
  end

  delegate :valid?, to: :phone

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
