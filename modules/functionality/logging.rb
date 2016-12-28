require 'sequel'

require_relative '../../bot-feature.rb'

$messages = {}

module ModelHandlers
  # Given a Discordrb::Message, give a model instance of a Message.
  # Creates if necessary.
  def get_message(bot, discord_message, server=nil)
    bot.db[:users].find
    message = bot.db[:messages].where(discord_id: discord_message.id).all
    puts "res: \"#{message}\""
    if message.size == 0
      user = get_user bot, discord_message.author
      server = get_server bot, server
      channel = get_channel bot, discord_message.channel
    
      message = bot.db[:messages].insert(user_id: user, channel_id: channel,
                                         server_id: server,
                                         timestamp: Time.now,
                                         message: discord_message.to_s)
    end

    message
  end

  # Given a Discordrb::User, give a model instance of a User.
  # Creates if necessary.
  def get_user(bot, discord_user)
    user = bot.db[:users].where(discord_id: discord_user.id).all

    if user.size == 0 
      user = bot.db[:users].insert(discord_id: discord_user.id)
    end

    user
  end

  # Given a Discordrb::Server, give a model instance of a server.
  # Creates if necessary.
  def get_server(bot, discord_server)
    server = bot.db[:servers].where(discord_id: discord_server.id).all

    if server.size == 0
      server = bot.db[:servers].insert(discord_id: discord_server.id)
    end

    server
  end

  # Given a Discordrb::Channel, give a model instance of a channel.
  # Creates if necessary.
  def get_channel(bot, discord_channel)
    channel = bot.db[:channels].where(discord_id: discord_channel.id).all

    if channel.size == 0
      channel = bot.db[:channels].insert(discord_id: discord_channel.id)
    end

    channel
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
      # get_message(bot, event.message, event.server)
      $messages[event.message.id] = {
        user: event.message.author.username.to_s,
        timestamp: event.timestamp
      }

      if event.message.author.username == bot.profile.username
        $messages[event.message.id][:content] = event.message.content.to_s
      end
    end
  end

  def self.descendants
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
end
