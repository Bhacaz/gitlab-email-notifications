# frozen_string_literal: true

class CreateOnboardings < ActiveRecord::Migration[8.1]
  def change
    create_table :onboardings do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :state, null: false, default: 0
      t.string :message_id
      t.text :confirmation_link

      t.timestamps
    end
  end
end
