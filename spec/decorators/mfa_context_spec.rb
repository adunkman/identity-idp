require 'rails_helper'

describe MfaContext do
  let(:mfa) { MfaContext.new(user) }

  context 'with no user' do
    let(:user) {}

    describe '#auth_app_configuration' do
      it 'returns a AuthAppConfiguration object' do
        expect(mfa.auth_app_configuration).to be_a AuthAppConfiguration
      end
    end

    describe '#piv_cac_configuration' do
      it 'returns a PivCacConfiguration object' do
        expect(mfa.piv_cac_configuration).to be_a PivCacConfiguration
      end
    end

    describe '#phone_configurations' do
      it 'is empty' do
        expect(mfa.phone_configurations).to be_empty
      end
    end

    describe '#webauthn_configurations' do
      it 'is empty' do
        expect(mfa.webauthn_configurations).to be_empty
      end
    end

    describe '#backup_code_configurations' do
      it 'is empty' do
        expect(mfa.backup_code_configurations).to be_empty
      end
    end
  end

  context 'with a user' do
    let(:user) { create(:user) }

    describe '#auth_app_configuration' do
      it 'returns a AuthAppConfiguration object' do
        expect(mfa.auth_app_configuration).to be_a AuthAppConfiguration
      end
    end

    describe '#piv_cac_configuration' do
      it 'returns a PivCacConfiguration object' do
        expect(mfa.piv_cac_configuration).to be_a PivCacConfiguration
      end
    end

    describe '#phone_configurations' do
      it 'mirrors the user relationship' do
        expect(mfa.phone_configurations).to eq user.phone_configurations
      end
    end

    describe '#webauthn_configurations' do
      context 'with no user' do
        let(:user) {}

        it 'is empty' do
          expect(mfa.webauthn_configurations).to be_empty
        end
      end
    end

    describe '#backup_code_configurations' do
      let(:user) {}

      it 'is empty' do
        expect(mfa.backup_code_configurations).to be_empty
      end
    end
  end

  describe '#enabled_two_factor_configuration_counts_hash' do
    let(:count_hash) { MfaContext.new(user).enabled_two_factor_configuration_counts_hash }

    context 'no 2FA configurations' do
      let(:user) { build(:user) }

      it 'returns an empty hash' do
        hash = {}

        expect(count_hash).to eq hash
      end
    end

    context 'with phone configuration' do
      let(:user) { build(:user, :signed_up) }

      it 'returns 1 for phone' do
        hash = { phone: 1 }

        expect(count_hash).to eq hash
      end
    end

    context 'with PIV/CAC configuration' do
      let(:user) { build(:user, :with_piv_or_cac) }

      it 'returns 1 for piv_cac' do
        hash = { piv_cac: 1 }

        expect(count_hash).to eq hash
      end
    end

    context 'with authentication app configuration' do
      let(:user) { build(:user, :with_authentication_app) }

      it 'returns 1 for auth_app' do
        hash = { auth_app: 1 }

        expect(count_hash).to eq hash
      end
    end

    context 'with webauthn configuration' do
      let(:user) { build(:user, :with_webauthn) }

      it 'returns 1 for webauthn' do
        hash = { webauthn: 1 }

        expect(count_hash).to eq hash
      end
    end

    context 'with authentication app and webauthn configurations' do
      let(:user) { build(:user, :with_authentication_app, :with_webauthn) }

      it 'returns 1 for each' do
        hash = { auth_app: 1, webauthn: 1 }

        expect(count_hash).to eq hash
      end
    end

    context 'with authentication app and phone configurations' do
      let(:user) { build(:user, :with_authentication_app, :signed_up) }

      it 'returns 1 for each' do
        hash = { phone: 1, auth_app: 1 }

        expect(count_hash).to eq hash
      end
    end

    context 'with PIV/CAC and phone configurations' do
      let(:user) { build(:user, :with_piv_or_cac, :signed_up) }

      it 'returns 1 for each' do
        hash = { phone: 1, piv_cac: 1 }

        expect(count_hash).to eq hash
      end
    end

    context 'with 1 phone and 2 webauthn configurations' do
      let(:user) { build(:user, :signed_up) }

      it 'returns 1 for phone and 2 for webauthn' do
        create_list(:webauthn_configuration, 2, user: user)
        hash = { phone: 1, webauthn: 2 }

        expect(count_hash).to eq hash
      end
    end

    context 'with 2 phones and 2 webauthn configurations' do
      it 'returns 2 for each' do
        user = create(:user, :signed_up)
        create(:phone_configuration, user: user, phone: '+1 703-555-1213')
        create_list(:webauthn_configuration, 2, user: user)
        count_hash = MfaContext.new(user.reload).enabled_two_factor_configuration_counts_hash
        hash = { phone: 2, webauthn: 2 }

        expect(count_hash).to eq hash
      end
    end
  end
end
