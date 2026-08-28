# frozen_string_literal: true

RSpec.describe MuteRule do
  describe '.candidates' do
    it 'builds exact-match candidates for available mute types' do
      expect(described_class.candidates(from_identifier: '@bot', repo: 'foo/bar', mr_iid: '42')).to eq(
        from_identifier: '@bot',
        repo: 'foo/bar',
        merge_request: 'foo/bar!42'
      )
    end

    it 'omits merge request when repo or mr_iid is missing' do
      expect(described_class.candidates(repo: 'foo/bar')).to eq(repo: 'foo/bar')
      expect(described_class.candidates(mr_iid: '42')).to eq({})
    end
  end

  describe '.muted?' do
    let(:user) { User.create!(uid: 'u1', email: 'u1@example.com') }

    it 'matches any rule with OR semantics' do
      user.mute_rules.create!(rule_type: :repo, value: 'foo/bar')

      expect(described_class.muted?(user, repo: 'foo/bar')).to be(true)
      expect(described_class.muted?(user, from_identifier: '@bot')).to be(false)
    end
  end

  describe '#display_label' do
    def build_mute_rule(**attrs)
      described_class.new(**attrs)
    end

    def from_identifier_attrs
      { rule_type: :from_identifier, value: '@bot', display_name: 'petal-jenkins-mr-token' }
    end

    it 'formats merge requests for the sidebar' do
      mute_rule = build_mute_rule(rule_type: :merge_request, value: 'foo/bar!42')

      expect(mute_rule.display_label).to eq('Merge Request: foo/bar !42')
    end

    it 'formats display_name and value together when display_name is present' do
      mute_rule = build_mute_rule(**from_identifier_attrs)

      expect(mute_rule.display_label).to eq('From: petal-jenkins-mr-token (@bot)')
    end
  end

  describe 'display_name normalization' do
    subject(:mute_rule) do
      described_class.create!(
        user: User.create!(uid: 'u2', email: 'u2@example.com'),
        rule_type: :repo,
        value: 'foo/bar',
        display_name: 'foo/bar'
      )
    end

    it 'clears display_name when it matches value' do
      expect(mute_rule.display_name).to be_nil
    end
  end
end
