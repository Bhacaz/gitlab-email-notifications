# frozen_string_literal: true

class CreateMuteRules < ActiveRecord::Migration[8.1]
  def change
    create_table :mute_rules do |t|
      t.references :user, null: false, foreign_key: true
      t.string :rule_type, null: false
      t.string :value, null: false

      t.timestamps
    end

    add_index :mute_rules, %i[user_id rule_type value], unique: true
  end
end
