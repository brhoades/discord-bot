Class.new(Sequel::Migration) do
  def up
    create_table(:chronic) do
      primary_key :id

      foreign_key :user_id, :users, key: :id
      foreign_key :server_id, :servers, key: :id
      foreign_key :channel_id, :channels, key: :id

      Time :time
      String :reminder
    end
  end

  def down
    drop_table(:chronic)
  end
end
