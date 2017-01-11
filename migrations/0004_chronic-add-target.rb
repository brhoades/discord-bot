Class.new(Sequel::Migration) do
  def up
    add_column :chronic, :target, String
  end

  def down
    drop_column :chronic, :target
  end
end
