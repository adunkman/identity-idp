module Idv
  class PhoneStep
    def initialize(idv_session:)
      self.idv_session = idv_session
    end

    def submit(step_params)
      self.step_params = step_params
      self.idv_result = Idv::Agent.new(applicant).proof(:address)
      increment_attempts_count
      success = idv_result[:success]
      update_idv_session if success
      FormResponse.new(
        success: success, errors: idv_result[:errors],
        extra: extra_analytics_attributes
      )
    end

    def failure_reason
      return :fail if idv_session.step_attempts[:phone] >= Idv::Attempter.idv_max_attempts
      return :jobfail if idv_result[:exception].present?
      return :warning if idv_result[:success] != true
    end

    private

    attr_accessor :idv_session, :step_params, :idv_result

    def applicant
      @applicant ||= idv_session.applicant.merge(step_params)
    end

    def increment_attempts_count
      idv_session.step_attempts[:phone] += 1
    end

    def update_idv_session
      idv_session.address_verification_mechanism = :phone
      idv_session.applicant = applicant
      idv_session.vendor_phone_confirmation = true
      idv_session.user_phone_confirmation = phone_matches_user_phone?
    end

    def phone_matches_user_phone?
      user_phone = PhoneFormatter.format(idv_session.current_user.phone)
      applicant_phone = PhoneFormatter.format(applicant[:phone])
      return false unless user_phone.present? && applicant_phone.present?
      user_phone == applicant_phone
    end

    def extra_analytics_attributes
      idv_result.except(:errors, :success)
    end
  end
end
