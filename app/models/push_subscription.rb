# frozen_string_literal: true

class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true, uniqueness: { scope: :user_id }
  validates :p256dh, presence: true
  validates :auth, presence: true

  def as_web_push_subscription
    {
      endpoint: endpoint,
      keys: {
        p256dh: p256dh,
        auth: auth
      }
    }
  end
end
