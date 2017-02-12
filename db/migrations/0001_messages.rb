class Messages < ActiveRecord::Migration
  def change
    create_table(:users) do |t|
      t.time :last_seen

      # Discord's id for this user
      t.bigint :discord_id

      t.timestamps
    end

    create_table(:servers) do |t|
      # Discord's id for this server
      t.bigint :discord_id

      t.timestamps
    end

    create_table(:channels) do |t|
      # Discord's id for this channel
      t.bigint :discord_id

      t.timestamps
    end

    create_table(:messages) do |t|
      t.string :text

      t.boolean :ignore, default: false
      t.boolean :deleted, default: false
      t.boolean :edited, default: false

      t.column :user_id, :integer
      t.column :server_id, :integer
      t.column :channel_id, :integer

      # Discord's id for this message
      t.bigint :discord_id
      t.timestamps
    end

  end
end
