# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, foreign_key: true, null: false
      t.string :message_id, null: false # ActionMailbox::InboundEmail#message_id
      t.string :title
      t.string :repo
      t.string :summary
      t.string :link
      t.string :unsubscribe_link
      t.boolean :hidden, default: false, null: false

      t.timestamps
      t.index :message_id
    end
  end
end
