# frozen_string_literal: true

class MuteRule < ApplicationRecord
  RULE_TYPES = {
    from_identifier: 'From',
    repo: 'Repository',
    merge_request: 'Merge Request'
  }.freeze

  belongs_to :user

  enum :rule_type, RULE_TYPES.keys.index_with(&:to_s), validate: true

  validates :value, presence: true,
                    uniqueness: { scope: %i[user_id rule_type], case_sensitive: true }

  scope :ordered, -> { order(:rule_type, :value) }

  def self.muted?(user, attrs)
    candidates(attrs).any? do |rule_type, value|
      user.mute_rules.exists?(rule_type: rule_type, value: value)
    end
  end

  def self.candidates(attrs)
    attrs = attrs.symbolize_keys

    {}.tap do |candidates|
      candidates[:from_identifier] = attrs[:from_identifier] if attrs[:from_identifier].present?
      candidates[:repo] = attrs[:repo] if attrs[:repo].present?
      if attrs[:repo].present? && attrs[:mr_iid].present?
        candidates[:merge_request] = "#{attrs[:repo]}!#{attrs[:mr_iid]}"
      end
    end
  end

  def display_label
    "#{RULE_TYPES.fetch(rule_type.to_sym)}: #{display_value}"
  end

  def display_value
    case rule_type.to_sym
    when :merge_request
      repo, mr_iid = value.split('!', 2)
      repo.present? && mr_iid.present? ? "#{repo} !#{mr_iid}" : value
    else
      value
    end
  end
end
