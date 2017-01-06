module ModelHandlers
  # Given a Discordrb::Message, give a model instance of a Message.
  # Creates if necessary.
  def get_message(bot, discord_message, server=nil)
    message = bot.db[:messages].where(discord_id: discord_message.id).first

    if not message
      user = get_user bot, discord_message.author
      server = get_server bot, server
      channel = get_channel bot, discord_message.channel
      message = bot.db[:messages].insert(user_id: user[:id], channel_id: channel[:id],
                                         server_id: server[:id],
                                         discord_id: discord_message.id,
                                         timestamp: Time.now,
                                         message: discord_message.to_s)
      bot.db[:messages].where(id: message).first
    end
  end

  # Given a Discordrb::User, give a model instance of a User.
  # Creates if necessary.
  def get_user(bot, discord_user)
    user = bot.db[:users].where(discord_id: discord_user.id).first

    if not user or (user.is_a? Array and user.length == 0)
      user_id = bot.db[:users].insert(discord_id: discord_user.id)
      user = bot.db[:users].where(id: user_id).all
    end

    if user.is_a? Array
      user.first
    else
      user
    end
  end

  # Given a Discordrb::Server, give a model instance of a server.
  # Creates if necessary.
  def get_server(bot, discord_server)
    server = bot.db[:servers].where(discord_id: discord_server.id).all

    if not server or (server.is_a? Array and server.length == 0)
      server_id = bot.db[:servers].insert(discord_id: discord_server.id)
      server = bot.db[:servers].where(id: server_id).all
    end

    if server.is_a? Array
      server.first
    else
      server
    end
  end

  # Given a Discordrb::Channel, give a model instance of a channel.
  # Creates if necessary.
  def get_channel(bot, discord_channel)
    channel = bot.db[:channels].where(discord_id: discord_channel.id).first

    if not channel or (channel.is_a? Array and channel.length == 0)
      channel_id = bot.db[:channels].insert(discord_id: discord_channel.id)
      channel = bot.db[:channels].where(id: channel_id).all
    end

    if channel.is_a? Array
      channel.first
    else
      channel
    end
  end
end
