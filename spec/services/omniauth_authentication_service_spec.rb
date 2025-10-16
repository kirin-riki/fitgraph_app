require 'rails_helper'

RSpec.describe OmniauthAuthenticationService, type: :service do
  let(:uid) { '12345' }
  let(:email) { 'test@example.com' }
  let(:name) { 'Test User' }

  describe '#call' do
    context 'Google OAuth認証の場合' do
      let(:auth) do
        OmniAuth::AuthHash.new({
          provider: 'google_oauth2',
          uid: uid,
          info: {
            email: email,
            name: name
          }
        })
      end

      context '同じメールアドレスのユーザーが存在する場合' do
        let!(:existing_user) do
          User.create!(
            name: 'Existing User',
            email: email,
            password: 'password123',
            password_confirmation: 'password123'
          )
        end

        it '既存ユーザーにOAuth情報を紐付ける' do
          service = OmniauthAuthenticationService.new(auth)
          user = service.call

          expect(user.id).to eq(existing_user.id)
          expect(user.provider).to eq('google_oauth2')
          expect(user.uid).to eq(uid)
          expect(user.email).to eq(email)
        end

        it 'ユーザー数が増えない' do
          expect do
            OmniauthAuthenticationService.new(auth).call
          end.not_to change(User, :count)
        end
      end

      context '同じメールアドレスのユーザーが存在しない場合' do
        it '新しいユーザーを作成する' do
          expect do
            OmniauthAuthenticationService.new(auth).call
          end.to change(User, :count).by(1)
        end

        it 'OAuth情報を持つユーザーが作成される' do
          user = OmniauthAuthenticationService.new(auth).call

          expect(user).to be_persisted
          expect(user.provider).to eq('google_oauth2')
          expect(user.uid).to eq(uid)
          expect(user.email).to eq(email)
          expect(user.name).to eq(name)
        end

        it 'パスワードが自動生成される' do
          user = OmniauthAuthenticationService.new(auth).call

          expect(user.encrypted_password).to be_present
        end
      end
    end

    context 'LINE OAuth認証の場合' do
      let(:auth) do
        OmniAuth::AuthHash.new({
          provider: 'line',
          uid: uid,
          info: {
            email: email,
            name: name
          }
        })
      end

      context 'provider と uid の組み合わせでユーザーが存在する場合' do
        let!(:existing_user) do
          User.create!(
            name: 'Existing LINE User',
            email: 'different@example.com',
            password: 'password123',
            password_confirmation: 'password123',
            provider: 'line',
            uid: uid
          )
        end

        it '既存ユーザーを返す' do
          user = OmniauthAuthenticationService.new(auth).call

          expect(user.id).to eq(existing_user.id)
        end

        it 'ユーザー数が増えない' do
          expect do
            OmniauthAuthenticationService.new(auth).call
          end.not_to change(User, :count)
        end
      end

      context 'provider と uid の組み合わせでユーザーが存在しない場合' do
        it '新しいユーザーを作成する' do
          expect do
            OmniauthAuthenticationService.new(auth).call
          end.to change(User, :count).by(1)
        end

        it 'OAuth情報を持つユーザーが作成される' do
          user = OmniauthAuthenticationService.new(auth).call

          expect(user).to be_persisted
          expect(user.provider).to eq('line')
          expect(user.uid).to eq(uid)
          expect(user.email).to eq(email)
          expect(user.name).to eq(name)
        end
      end
    end

    context 'メールアドレスが提供されない場合' do
      let(:auth) do
        OmniAuth::AuthHash.new({
          provider: 'line',
          uid: uid,
          info: {
            email: nil,
            name: name
          }
        })
      end

      it '代替のメールアドレスを生成する' do
        user = OmniauthAuthenticationService.new(auth).call

        expect(user.email).to eq("#{uid}-line@example.com")
      end
    end

    context '名前が提供されない場合' do
      let(:auth) do
        OmniAuth::AuthHash.new({
          provider: 'line',
          uid: uid,
          info: {
            email: nil,
            name: nil
          }
        })
      end

      it 'プロバイダ名を使用した名前を設定する' do
        user = OmniauthAuthenticationService.new(auth).call

        expect(user.name).to eq('Lineユーザー')
      end
    end

    context '空の情報が提供される場合' do
      let(:auth) do
        OmniAuth::AuthHash.new({
          provider: 'google_oauth2',
          uid: uid,
          info: {
            email: '',
            name: ''
          }
        })
      end

      it '代替情報でユーザーを作成する' do
        user = OmniauthAuthenticationService.new(auth).call

        expect(user).to be_persisted
        expect(user.email).to eq("#{uid}-google_oauth2@example.com")
        expect(user.name).to eq('Google_oauth2ユーザー')
      end
    end

    context 'ユーザー認証に成功する場合' do
      let(:auth) do
        OmniAuth::AuthHash.new({
          provider: 'google_oauth2',
          uid: uid,
          info: {
            email: email,
            name: name
          }
        })
      end

      it '成功ログを出力する' do
        allow(Rails.logger).to receive(:debug)

        OmniauthAuthenticationService.new(auth).call

        expect(Rails.logger).to have_received(:debug).with(/User authenticated/)
      end
    end
  end
end
