module TwoFactorAuthentication
  class BackupCodeVerificationController < ApplicationController
    include TwoFactorAuthenticatable

    prepend_before_action :authenticate_user
    prepend_before_action :handle_if_all_codes_used

    # rubocop:disable Layout/FirstParameterIndentation
    def show
      analytics.track_event(
          Analytics::MULTI_FACTOR_AUTH_ENTER_BACKUP_CODE_VISIT, context: context
        )
      @presenter = TwoFactorAuthCode::BackupCodePresenter.new(
          view: view_context,
          data: { current_user: current_user }
        )
      @backup_code_form = BackupCodeVerificationForm.new(current_user)
    end

    def create
      @backup_code_form = BackupCodeVerificationForm.new(current_user)
      result = @backup_code_form.submit(backup_code_params)
      analytics.track_event(Analytics::MULTI_FACTOR_AUTH, result.to_h)

      handle_result(result)
    end

    private

    def handle_if_all_codes_used
      count = BackupCodeConfiguration.where(user_id: current_user.id, used: true).count
      return unless count == (BackupCodeGenerator::NUMBER_OF_CODES - 1)
      BackupCodeGenerator.new(current_user).delete_existing_codes
      redirect_to backup_code_setup_url
    end

    def presenter_for_two_factor_authentication_method
      TwoFactorAuthCode::BackupCodePresenter.new(
            view: view_context,
            data: { current_user: current_user }
          )
    end
    # rubocop:enable Layout/FirstParameterIndentation

    def handle_invalid_backup_code
      update_invalid_user

      flash.now[:error] = t('two_factor_authentication.invalid_backup_code')

      if decorated_user.locked_out?
        handle_second_factor_locked_user('backup_code')
      else
        render_show_after_invalid
      end
    end

    def handle_result(result)
      if result.success?
        handle_valid_backup_code
      else
        handle_invalid_backup_code
      end
    end

    def backup_code_params
      params.require(:backup_code_verification_form).permit :backup_code
    end

    def handle_valid_backup_code
      handle_valid_otp_for_authentication_context
      redirect_to manage_personal_key_url
      reset_otp_session_data
      user_session.delete(:mfa_device_remembered)
    end
  end
end
