Class.new(Sequel::Migration) do
  def up
    create_table(:messages) do
      primary_key :id
      foreign_key :user_id, :users, key: :id
      foreign_key :server_id, :servers, key: :id
      foreign_key :channel_id, :channels, key: :id

      Time :timestamp
      String :message

      boolean :ignore, default: false
      boolean :deleted, default: false
      boolean :edited, default: false
    end

    create_table(:users) do
      primary_key :id

      # Discord's id for this user
      Integer :discord_id
    end

    create_table(:servers) do
      primary_key :id

      # Discord's id for this server
      Integer :discord_id
    end

    create_table(:channels) do
      primary_key :id

      # Discord's id for this channel
      Integer :discord_id
    end
  end

  def down
    drop_table(:messages)
    drop_table(:users)
    drop_table(:servers)
    drop_table(:channels)
  end
end
