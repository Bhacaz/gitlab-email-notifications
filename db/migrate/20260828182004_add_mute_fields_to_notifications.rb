# frozen_string_literal: true

class AddMuteFieldsToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :from_identifier, :string
    add_column :notifications, :mr_iid, :string

    add_index :notifications, :from_identifier
    add_index :notifications, %i[repo mr_iid]
  end
end
