class MessagesAddLocks < ActiveRecord::Migration
  def self.up
    add_column :messages, :lock_version, :integer
  end

  def self.down
    remove_column :messages, :lock_version
  end
end
