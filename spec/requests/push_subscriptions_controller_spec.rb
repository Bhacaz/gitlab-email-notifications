# frozen_string_literal: true

RSpec.describe 'PushSubscriptions' do
  let(:endpoint) { 'https://example.com/push/1' }
  let(:valid_params) do
    { push_subscription: { endpoint:, keys: { p256dh: 'p256key', auth: 'authkey' } } }
  end
  let(:user) do
    User.create!(name: 'Test User', username: 'testuser', uid: 'uid-ps-spec',
                 email: 'testuser-ps@example.com', email_prefix: 'testuser-ps')
  end

  describe 'POST /push_subscription' do
    context 'when not logged in' do
      it 'redirects to sign in' do
        post '/push_subscription', params: valid_params, as: :json
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'when logged in' do
      before { sign_in_as(user) }

      it 'creates a new push subscription and returns 201' do
        post '/push_subscription', params: valid_params, as: :json

        expect(response).to have_http_status(:created)
      end

      it 'persists the subscription with correct attributes' do
        post '/push_subscription', params: valid_params, as: :json

        sub = user.push_subscriptions.find_by(endpoint:)
        expect(sub).to have_attributes(p256dh: 'p256key', auth: 'authkey')
      end

      context 'when subscription already exists for the same endpoint' do
        before { user.push_subscriptions.create!(endpoint:, p256dh: 'old_p256', auth: 'old_auth') }

        it 'returns 201' do
          post '/push_subscription',
               params: { push_subscription: { endpoint:, keys: { p256dh: 'new_p256', auth: 'new_auth' } } },
               as: :json
          expect(response).to have_http_status(:created)
        end

        it 'updates the existing record (upsert)' do
          post '/push_subscription',
               params: { push_subscription: { endpoint:, keys: { p256dh: 'new_p256', auth: 'new_auth' } } },
               as: :json
          expect(user.push_subscriptions.count).to eq(1)
          expect(user.push_subscriptions.first.p256dh).to eq('new_p256')
        end
      end

      it 'returns 422 when endpoint is missing' do
        post '/push_subscription',
             params: { push_subscription: { endpoint: '', keys: { p256dh: 'abc', auth: 'def' } } },
             as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['errors']).to be_present
      end
    end
  end

  describe 'DELETE /push_subscription' do
    context 'when not logged in' do
      it 'redirects to sign in' do
        delete '/push_subscription', params: { endpoint: }, as: :json
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'when logged in' do
      before { sign_in_as(user) }

      it 'destroys the subscription and returns 204' do
        user.push_subscriptions.create!(endpoint:, p256dh: 'abc', auth: 'def')

        delete '/push_subscription', params: { endpoint: }, as: :json

        expect(response).to have_http_status(:no_content)
        expect(user.push_subscriptions.find_by(endpoint:)).to be_nil
      end

      it 'returns 204 even when subscription does not exist (idempotent)' do
        delete '/push_subscription', params: { endpoint: 'https://example.com/nonexistent' }, as: :json
        expect(response).to have_http_status(:no_content)
      end

      context 'when subscription belongs to another user' do
        let(:other_endpoint) { 'https://example.com/push/other' }

        before do
          other = User.create!(name: 'Other', username: 'other', uid: 'uid-other',
                               email: 'other@example.com', email_prefix: 'other')
          other.push_subscriptions.create!(endpoint: other_endpoint, p256dh: 'abc', auth: 'def')
        end

        it 'returns 204' do
          delete '/push_subscription', params: { endpoint: other_endpoint }, as: :json
          expect(response).to have_http_status(:no_content)
        end

        it 'does not destroy the other user subscription' do
          delete '/push_subscription', params: { endpoint: other_endpoint }, as: :json
          expect(PushSubscription.find_by(endpoint: other_endpoint)).to be_present
        end
      end
    end
  end
end
