# frozen_string_literal: true

module BooleanHelper
  def cast_boolean(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end
