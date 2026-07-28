# frozen_string_literal: true

class AddStatusToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :status, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE notifications SET status = 2 WHERE hidden = 1
        SQL
      end
    end

    remove_column :notifications, :hidden, :boolean
  end
end
