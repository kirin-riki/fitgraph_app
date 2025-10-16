require 'rails_helper'

RSpec.describe TwoFactorAuthService, type: :service do
  let(:user) do
    User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
  end

  describe '#provisioning_uri' do
    it 'OTP用のprovisioning URIを返す' do
      service = TwoFactorAuthService.new(user)

      uri = service.provisioning_uri

      expect(uri).to be_a(String)
      expect(uri).to start_with('otpauth://totp/')
      expect(uri).to include(CGI.escape(user.email))
      expect(uri).to include('Fitgraph')
    end

    context 'カスタムissuerを指定した場合' do
      it '指定したissuerを含むURIを返す' do
        service = TwoFactorAuthService.new(user, issuer: 'CustomApp')

        uri = service.provisioning_uri

        expect(uri).to include('CustomApp')
        expect(uri).not_to include('Fitgraph')
      end
    end
  end

  describe '#qr_code_uri' do
    it 'provisioning_uriのエイリアスとして動作する' do
      service = TwoFactorAuthService.new(user)

      expect(service.qr_code_uri).to eq(service.provisioning_uri)
    end
  end
end
