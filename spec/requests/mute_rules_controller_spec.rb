# frozen_string_literal: true

RSpec.describe 'MuteRules' do
  let!(:user) { User.create!(uid: 'u1', email: 'u1@example.com') }
  let!(:notification) do
    Notification.create!(
      user: user,
      message_id: SecureRandom.hex,
      reason: :mr_comment,
      repo: 'foo/bar',
      mr_iid: '42',
      from_identifier: '@group_123_bot_deadbeef',
      title: 'comment',
      status: :new
    )
  end

  before { sign_in_as(user) }

  describe 'GET /mute_rules' do
    let!(:mute_rule) { user.mute_rules.create!(rule_type: :repo, value: 'foo/bar') }

    it 'renders the user mute rules page' do
      get mute_rules_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Mute Rules')
      expect(response.body).to include('foo/bar')
    end
  end

  describe 'POST /notifications/:notification_id/mute_rule' do
    it 'creates a mute rule and marks the notification done' do
      post notification_mute_rule_path(notification), params: { rule_type: 'merge_request' }

      expect(response).to have_http_status(:found)
      expect(user.mute_rules.pluck(:rule_type, :value)).to contain_exactly(['merge_request', 'foo/bar!42'])
      expect(notification.reload).to be_status_done
    end

    it 'silently deduplicates an existing rule' do
      user.mute_rules.create!(rule_type: :repo, value: 'foo/bar')

      expect do
        post notification_mute_rule_path(notification), params: { rule_type: 'repo' }
      end.not_to change(MuteRule, :count)

      expect(notification.reload).to be_status_done
    end
  end

  describe 'DELETE /mute_rules/:id' do
    let!(:mute_rule) { user.mute_rules.create!(rule_type: :repo, value: 'foo/bar') }

    it 'removes the rule' do
      delete mute_rule_path(mute_rule)

      expect(response).to redirect_to(mute_rules_path)
      expect(user.mute_rules.reload).to be_empty
    end
  end
end
