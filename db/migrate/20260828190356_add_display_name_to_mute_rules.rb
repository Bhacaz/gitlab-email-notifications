# frozen_string_literal: true

class AddDisplayNameToMuteRules < ActiveRecord::Migration[8.1]
  def change
    add_column :mute_rules, :display_name, :string
  end
end
