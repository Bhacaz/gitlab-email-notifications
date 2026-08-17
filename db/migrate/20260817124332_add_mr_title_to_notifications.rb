# frozen_string_literal: true

class AddMrTitleToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :mr_title, :string
  end
end
