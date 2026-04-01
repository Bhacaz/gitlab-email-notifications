# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user

  scope :visible, -> { where(hidden: false) }
end
