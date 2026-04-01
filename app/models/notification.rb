# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user

  enum :reason, {
    unknow: 0,
    pipeline_failed: 1
  }, prefix: true
  
  scope :visible, -> { where(hidden: false) }
end
