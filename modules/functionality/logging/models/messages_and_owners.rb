class User < ActiveRecord::Base
end

class Channel < ActiveRecord::Base
end

class Server < ActiveRecord::Base
end

class Message < ActiveRecord::Base
  # TODO: Ensure_message w/ event
  belongs_to :server
  belongs_to :channel
  belongs_to :user

  # When given a MessageEvent, ensures that a message exists and returns it
  def self.ensure(message)
    old_message = Message.where(discord_id: message.id)
    if old_message.size > 0
      old_message.user.last_seen = Time.now
      old_message.user.save!
      return old_message.first
    end

    # Active Record
    user = User.where(discord_id: message.author.id).first_or_initialize
    user.last_seen = Time.now
    user.save!

    channel = Channel.where(discord_id: message.channel.id).first_or_initialize do |c|
      c.save!
    end

    server = Server.where(discord_id: message.channel.server.id).first_or_initialize do |s|
      s.save!
    end

    Message.where(
      text: message.to_s,
      user: user,
      server: server,
      channel: channel,
      discord_id: message.id).first_or_initialize do |m|
      m.save!
    end
  end
end
