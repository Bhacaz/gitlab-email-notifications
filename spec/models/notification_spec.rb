# frozen_string_literal: true

RSpec.describe Notification do
  describe '.visible_filters' do
    let!(:user) { User.create!(uid: 'u1', email: 'u1@example.com') }

    let!(:failed_foo) do
      described_class.create!(user: user, message_id: SecureRandom.hex, reason: :pipeline_failed, repo: 'foo/bar',
                              title: 'f1', status: :new)
    end
    let!(:failed_baz) do
      described_class.create!(user: user, message_id: SecureRandom.hex, reason: :pipeline_failed, repo: 'baz/qux',
                              title: 'f2', status: :seen)
    end
    let!(:fixed) do
      described_class.create!(user: user, message_id: SecureRandom.hex, reason: :pipeline_fixed, repo: 'foo/bar',
                              title: 'x', status: :new)
    end
    let!(:done) do
      described_class.create!(user: user, message_id: SecureRandom.hex, reason: :pipeline_failed, repo: 'foo/bar',
                              title: 'd', status: :done)
    end

    it 'returns visible (non-done) notifications, excluding done ones' do
      result = user.notifications.visible_filters.pluck(:id)
      expect(result).to contain_exactly(failed_foo.id, failed_baz.id, fixed.id)
      expect(result).not_to include(done.id)
    end

    it 'filters by reason' do
      expect(user.notifications.visible_filters(reason: 'pipeline_failed').pluck(:id))
        .to contain_exactly(failed_foo.id, failed_baz.id)
    end

    it 'filters by repo' do
      expect(user.notifications.visible_filters(repo: 'foo/bar').pluck(:id))
        .to contain_exactly(failed_foo.id, fixed.id)
    end

    it 'filters by status' do
      expect(user.notifications.visible_filters(status: 'seen').pluck(:id)).to contain_exactly(failed_baz.id)
    end

    it 'ignores an unknown status filter' do
      expect(described_class.visible_filters(status: 'nope')).not_to be_empty
    end

    it 'combines filters' do
      expect(user.notifications.visible_filters(reason: 'pipeline_failed', repo: 'foo/bar').pluck(:id))
        .to contain_exactly(failed_foo.id)
    end
  end
end
