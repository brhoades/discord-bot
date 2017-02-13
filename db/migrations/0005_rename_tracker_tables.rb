class RenameTrackerTables < ActiveRecord::Migration
  def self.up
    rename_table :overwatch_history, :overwatch_histories
    rename_table :battlefield_history, :battlefield_histories
  end

  def self.down
    rename_table :overwatch_hostories, :overwatch_history
    rename_table :battlefield_hostories, :battlefield_history
  end
end
