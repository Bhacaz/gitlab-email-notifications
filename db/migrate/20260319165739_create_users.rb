# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :username
      t.string :email
      t.string :uid
      t.string :avatar_url
      t.string :email_prefix, null: false

      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :uid, unique: true
    add_index :users, :email_prefix, unique: true
  end
end
