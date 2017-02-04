class Messages < ActiveRecord::Migration
  def change
    create_table(:messages) do |t|
      t.time :timestamp
      t.string :message

      t.boolean :ignore, default: false
      t.boolean :deleted, default: false
      t.boolean :edited, default: false

      # Discord's id for this message
      t.integer :discord_id
    end

    create_table(:users) do |t|
      t.time :last_seen

      # Discord's id for this user
      t.integer :discord_id
    end

    create_table(:servers) do |t|
      # Discord's id for this server
      t.integer :discord_id
    end

    create_table(:channels) do |t|
      # Discord's id for this channel
      t.integer :discord_id
    end
  end
end
