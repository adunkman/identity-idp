module Users
  class TotpSetupController < ApplicationController
    before_action :authenticate_user!
    before_action :confirm_two_factor_authenticated, if: :two_factor_enabled?

    def new
      return redirect_to account_url if current_user.totp_enabled?

      store_totp_secret_in_session
      track_event

      @code = new_totp_secret
      @qrcode = current_user.decorate.qrcode(new_totp_secret)
    end

    def confirm
      result = TotpSetupForm.new(current_user, new_totp_secret, params[:code].strip).submit

      analytics.track_event(Analytics::MULTI_FACTOR_AUTH_SETUP, result.to_h)

      if result.success?
        process_valid_code
      else
        process_invalid_code
      end
    end

    def disable
      if current_user.totp_enabled? && MfaPolicy.new(current_user).multiple_factors_enabled?
        process_successful_disable
      end
      redirect_to account_url
    end

    private

    def two_factor_enabled?
      MfaPolicy.new(current_user).two_factor_enabled?
    end

    def track_event
      properties = {
        user_signed_up: MfaPolicy.new(current_user).two_factor_enabled?,
        totp_secret_present: new_totp_secret.present?,
      }
      analytics.track_event(Analytics::TOTP_SETUP_VISIT, properties)
    end

    def store_totp_secret_in_session
      user_session[:new_totp_secret] = current_user.generate_totp_secret if new_totp_secret.nil?
    end

    def process_valid_code
      mark_user_as_fully_authenticated
      flash[:success] = t('notices.totp_configured')
      redirect_to url_after_entering_valid_code
      user_session.delete(:new_totp_secret)
    end

    def process_successful_disable
      analytics.track_event(Analytics::TOTP_USER_DISABLED)
      create_user_event(:authenticator_disabled)
      UpdateUser.new(user: current_user, attributes: { otp_secret_key: nil }).call
      flash[:success] = t('notices.totp_disabled')
    end

    def mark_user_as_fully_authenticated
      user_session[TwoFactorAuthentication::NEED_AUTHENTICATION] = false
      user_session[:authn_at] = Time.zone.now
    end

    def url_after_entering_valid_code
      return account_url if user_already_has_a_personal_key?

      policy = PersonalKeyForNewUserPolicy.new(user: current_user, session: session)

      if policy.show_personal_key_after_initial_2fa_setup?
        sign_up_personal_key_url
      else
        idv_jurisdiction_url
      end
    end

    def user_already_has_a_personal_key?
      TwoFactorAuthentication::PersonalKeyPolicy.new(current_user).configured?
    end

    def process_invalid_code
      flash[:error] = t('errors.invalid_totp')
      redirect_to authenticator_setup_url
    end

    def new_totp_secret
      user_session[:new_totp_secret]
    end
  end
end
