require 'sequel'

require_relative '../../bot-feature.rb'

$messages = {}

module ModelHandlers
  # Given a Discordrb::Message, give a model instance of a Message.
  # Creates if necessary.
  def get_message(bot, discord_message, server=nil)
    message = bot.db[:messages].where(discord_id: discord_message.id).first

    if not message
      user = get_user bot, discord_message.author
      server = get_server bot, server
      channel = get_channel bot, discord_message.channel
        puts %{
User: "#{user}"
Server: "#{server}"
Channel: "#{channel}"
}
      message = bot.db[:messages].insert(user_id: user[:id], channel_id: channel[:id],
                                         server_id: server[:id],
                                         timestamp: Time.now,
                                         message: discord_message.to_s)
      bot.db[:messages].where(id: message).first
    end
  end

  # Given a Discordrb::User, give a model instance of a User.
  # Creates if necessary.
  def get_user(bot, discord_user)
    user = bot.db[:users].where(discord_id: discord_user.id).first

    if not user
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

    if not server
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

    if not channel
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

class LoggingFeature < BotFeature
  include ModelHandlers

  def register_handlers(bot, scheduler)
    bot.message_delete do |event|
      next if $ignore.include?(event.id) or (event.respond_to?(:message) and $ignore.include?(event.message.id))
      next if event.channel and event.channel.name == "the_mod_lounge"
      channel = bot.find_channel("logs", event.channel.server.name)

      if channel.size == 0
        puts "#logs not found on #{event.channel.server.name}."
        next
      end
      channel = channel[0]

      if $messages.has_key?(event.id)
        if $messages[event.id].has_key?(:content) and event.channel.name.to_s == "logs"
          bot.send_message(event.channel.id, $messages[event.id][:content])
        else
          bot.send_message(channel.id, "A message by #{$messages[event.id][:user]} was deleted in ##{event.channel.name}")
        end
      else
        bot.send_message(channel.id, "A message was deleted in ##{event.channel.name}")
      end
    end

    bot.message do |event|
      get_message(bot, event.message, event.server)
      $messages[event.message.id] = {
        user: event.message.author.username.to_s,
        timestamp: event.timestamp
      }

      if event.message.author.username == bot.profile.username
        $messages[event.message.id][:content] = event.message.content.to_s
      end
    end
  end
end
