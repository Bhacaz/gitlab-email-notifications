# frozen_string_literal: true

class CreatePushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.text :endpoint, null: false
      t.string :p256dh, null: false
      t.string :auth, null: false

      t.timestamps
      t.index %i[user_id endpoint], unique: true
    end
  end
end
