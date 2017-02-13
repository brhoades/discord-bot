class OverwatchAndBattlefieldTrackedUsers < ActiveRecord::Migration
  def change
    create_table(:overwatch_tracked_users) do |t|
      t.column :name, :string

      # Users
      t.column :added_by_id, :integer
      t.column :target_id, :integer, default: nil, nil: true

      t.timestamps
    end

    create_table(:battlefield_tracked_users) do |t|
      t.column :name, :string

      # Users
      t.column :added_by_id, :integer
      t.column :target_id, :integer, default: nil, nil: true

      t.timestamps
    end
  end
end
