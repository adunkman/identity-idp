require 'rails_helper'

describe 'Account Reset Request: Delete Account', email: true do
  let(:user) { create(:user, :signed_up) }

  before do
    TwilioService::Utils.telephony_service = FakeSms
  end

  context 'as an LOA1 user' do
    it 'allows the user to delete their account after 24 hours' do
      signin(user.email, user.password)
      click_link t('two_factor_authentication.login_options_link_text')
      click_link t('devise.two_factor_authentication.account_reset.link')
      click_button t('account_reset.request.yes_continue')

      expect(page).
        to have_content strip_tags(
          t('account_reset.confirm_request.instructions', email: user.email)
        )
      expect(page).to have_content t('account_reset.confirm_request.security_note')
      expect(page).to have_content t('account_reset.confirm_request.close_window')

      reset_email

      Timecop.travel(Time.zone.now + 2.days) do
        AccountResetService.grant_tokens_and_send_notifications
        open_last_email
        click_email_link_matching(/delete_account\?token/)

        expect(page).to have_content(t('account_reset.delete_account.title'))
        expect(page).to have_current_path(account_reset_delete_account_path)

        click_on t('account_reset.delete_account.delete_button')

        expect(page).to have_content(
          strip_tags(
            t(
              'account_reset.confirm_delete_account.info',
              email: user.email,
              link: t('account_reset.confirm_delete_account.link_text')
            )
          )
        )
        expect(page).to have_current_path(account_reset_confirm_delete_account_path)
        expect(User.where(id: user.id)).to be_empty
        expect(last_email.subject).to eq t('user_mailer.account_reset_complete.subject')

        click_link t('account_reset.confirm_delete_account.link_text')

        expect(page).to have_current_path(sign_up_email_path)
      end
    end
  end

  context 'as an LOA1 user without a phone' do
    it 'does not tell the user that an SMS was sent to their registered phone' do
      user = create(:user, :with_authentication_app)
      signin(user.email, user.password)
      click_link t('two_factor_authentication.login_options_link_text')
      click_link t('devise.two_factor_authentication.account_reset.link')
      click_button t('account_reset.request.yes_continue')

      expect(page).
        to have_content strip_tags(
          t('account_reset.confirm_request.instructions', email: user.email)
        )
      expect(page).to_not have_content t('account_reset.confirm_request.security_note')
      expect(page).to have_content t('account_reset.confirm_request.close_window')

      # user should now be signed out
      visit account_path

      expect(page).to have_current_path(new_user_session_path)
    end
  end

  context 'as an LOA3 user' do
    let(:user) do
      create(
        :profile,
        :active,
        :verified,
        pii: { first_name: 'John', ssn: '111223333' }
      ).user
    end

    it 'does not allow the user to delete their account from 2FA screen' do
      signin(user.email, user.password)
      click_link t('two_factor_authentication.login_options_link_text')

      # Account reset link should not be present
      expect(page).to_not have_content(t('devise.two_factor_authentication.account_reset.link'))

      # Visiting account reset directly should redirect to 2FA
      visit account_reset_request_path

      expect(page.current_path).to eq(login_two_factor_path(otp_delivery_preference: :sms))
    end
  end
end