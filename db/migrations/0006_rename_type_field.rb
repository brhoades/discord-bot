class RenameTypeField < ActiveRecord::Migration
  def self.up
    rename_column :overwatch_histories, :type, :data_type
    rename_column :battlefield_histories, :type, :data_type
  end

  def self.down
    rename_column :overwatch_histories, :data_type, :type
    rename_column :battlefield_histories, :data_type, :type
  end
end
