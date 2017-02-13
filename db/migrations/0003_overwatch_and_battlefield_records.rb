class OverwatchAndBattlefieldRecords < ActiveRecord::Migration
  def change
    create_table(:overwatch_history) do |t|
      t.string :tag
      # See overwatch/models/logs.rb
      t.integer :type, default: 0

      t.json :data

      t.timestamps
    end

    create_table(:overwatch_aliases) do |t|
      t.string :short
      t.string :long

      t.timestamps
    end

    create_table(:battlefield_history) do |t|
      t.string :tag
      # See battlefield/models/logs.rb
      t.integer :type

      t.json :data

      t.timestamps
    end
  end
end
