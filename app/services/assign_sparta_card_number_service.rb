# frozen_string_literal: true

class AssignSpartaCardNumberService
  class AssignSpartaCardNumberError < StandardError; end

  def initialize(user)
    @user = user
  end

  def call
    customer_data = customer_info
    card_data = customer_data.dig('response', 'mainCard')
    add_card_number_to_user(card_data)
  end

  private

  def customer_info
    Spl::MeService.new(@user).call
  end

  def add_card_number_to_user(card_data)
    if card_data['status'] != 'A'
      raise AssignSpartaCardNumberError, I18n.t('spl.card_validation.errors.card_not_active')
    end
    if cards_assigned_user(card_data['no'])
      raise AssignSpartaCardNumberError, I18n.t('spl.card_validation.errors.wrong_owner')
    end

    @user.update(public_metadata: @user.public_metadata.merge(spl_no_card: card_data['no'],
                                                              spl_card_active: true))
  end

  def cards_assigned_user(card_number)
    Spree::User.find { |u| u.public_metadata['spl_no_card'] == card_number }.id != @user.id
  end
end
