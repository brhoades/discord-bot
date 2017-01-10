Class.new(Sequel::Migration) do
  def up
    create_table(:overwatch) do
      primary_key :id

      String :full_user
      String :short_user
    end
  end

  def down
    drop_table(:overwatch)
  end
end
