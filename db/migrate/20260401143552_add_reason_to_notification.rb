# frozen_string_literal: true

class AddReasonToNotification < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :reason, :integer, limit: 1, default: 0
  end
end
