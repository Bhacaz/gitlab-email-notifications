# frozen_string_literal: true

class User < ApplicationRecord
  validates :uid, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :email_prefix, presence: true, uniqueness: true

  has_many :notifications, dependent: :destroy

  before_validation :init_email_prefix

  def self.from_omniauth(auth)
    find_or_initialize_by(uid: auth.uid).tap do |user|
      user.name = auth.info.name
      user.username = auth.info.username
      user.email = auth.info.email
      user.avatar_url = auth.info.image
      user.save!
    end
  end

  private

  def init_email_prefix
    prefix = SecureRandom.hex(10).downcase
    while User.exists?(email_prefix: prefix)
      prefix = SecureRandom.hex(10).downcase
    end
    self.email_prefix = prefix
  end
end
