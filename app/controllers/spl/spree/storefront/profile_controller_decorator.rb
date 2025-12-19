# frozen_string_literal: true

module Spl
  module Spree
    module Storefront
      module ProfileControllerDecorator
        def self.prepended(base)
          base.before_action :validate_login_code_request, only: :login_code
        end

        def login_code
          phone = phone_parser
          Spl::SendOtpService.new(DateTime.current, phone.country_code, phone.national_number, current_store).call
          update_user_after_otp_request
          render_login_code_success(phone)
        rescue Spl::SendOtpService::SplSendOtpError => e
          handle_spl_error(e)
          render_login_code_error
        end

        def connect_loyalty_account
          assign_card_number(try_spree_current_user, current_store, params)
          redirect_to spree.edit_account_profile_path,
                      notice: ::Spree.t(:successfully_updated, resource: ::Spree.t(:account))
        rescue Spl::LoginAccountService::SplLoginAccountError, AssignSpartaCardNumberService::AssignSpartaCardNumberError,
               Spl::MeService::SplMeError => e
          handle_spl_error(e)
          render_connect_loyalty_account_error(try_spree_current_user.phone)
        end

        private

        def validate_login_code_request
          clear_errors
          validate_yc_terms
          validate_phone

          render_login_code_error if try_spree_current_user.errors.any?
        end

        def validate_yc_terms
          return if yc_terms_accepted?

          try_spree_current_user.errors.add(:base, I18n.t('spl.user.errors.must_accept_yc_terms'))
        end

        def validate_phone
          return if phone_parser.valid?

          try_spree_current_user.errors.add(:phone, I18n.t('spl.user.errors.invalid_phone'))
        end

        def yc_terms_accepted?
          ActiveModel::Type::Boolean.new.cast(login_code_params[:accept_yc_terms])
        end

        def phone_parser
          PhoneParserService.new(login_code_params[:phone])
        end

        def clear_errors
          try_spree_current_user.errors.clear
        end

        def render_login_code_error
          render turbo_stream: turbo_stream.replace(
            'loyalty_connect_form',
            partial: 'spl/loyalty_connect_form',
            locals: { user: try_spree_current_user }
          ),
                 status: :unprocessable_entity
        end

        def render_login_code_success(phone)
          render turbo_stream: turbo_stream.replace(
            'loyalty_connect_form',
            partial: 'spl/otp_code_form',
            locals: {
              user: try_spree_current_user,
              phone_e164: phone.respond_to?(:e164) ? phone.e164 : nil
            }
          ),
                 status: :ok
        end

        def render_connect_loyalty_account_error(phone)
          render turbo_stream: turbo_stream.replace(
            'otp_code_form',
            partial: 'spl/otp_code_form',
            locals: {
              user: try_spree_current_user,
              phone_e164: phone.respond_to?(:e164) ? phone.e164 : nil
            }
          ),
                 status: :unprocessable_entity
        end

        def update_user_after_otp_request
          try_spree_current_user.update!(
            phone: login_code_params[:phone],
            public_metadata: (try_spree_current_user.public_metadata || {}).merge('accept_yc_terms' => true)
          )
        end

        def handle_spl_error(error)
          payload = Spl::ErrorPayloadParser.parse(error.message) || error
          msg = Spl::ErrorTranslator.translate(payload)

          clear_errors
          try_spree_current_user.errors.add(:base, msg)
        end

        def assign_card_number(user, store, params)
          Spl::LoginAccountService.new(user, store, params).call
          AssignSpartaCardNumberService.new(user, store).call
        end

        def login_code_params
          params.require(:user).permit(:phone, :accept_yc_terms)
        end
      end
    end
  end
end
