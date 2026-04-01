# frozen_string_literal: true

class Onboarding < ApplicationRecord
  belongs_to :user

  enum :state, {
    pending: 0,
    awaiting_confirmation: 1,
    completed: 2
  }
end
