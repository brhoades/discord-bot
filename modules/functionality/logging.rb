require 'sequel'

require_relative '../../bot-feature.rb'
require_relative '../../modelhandlers.rb'

class LoggingFeature < BotFeature
  include ModelHandlers

  def register_handlers(bot, scheduler)
    bot.message do |event|
      # Stores the message by getting it
      get_message(bot, event.message, event.server)
    end

    bot.message_delete do |event|
      message = bot.db[:messages].where(discord_id: event.id).all.first
      puts "\"#{message}\""
      next if not message
      next if message[:ignore]

      if event.respond_to?(:message) and
        print "WAT"
        print message
        next
      end
      next if event.channel and event.channel.name == "the_mod_lounge"
      channel = bot.find_channel("logs", event.channel.server.name)

      if channel.size == 0
        puts "#logs not found on #{event.channel.server.name}."
        next
      end
      channel = channel.first
      user = bot.db[:users].where(id: message[:user_id]).all.first
      member = bot.member(event.channel.server, user[:discord_id])

      bot.db[:messages].where(id: message[:id]).update(deleted: true)

      return

      if event.channel.name.to_s == "logs" and member.current_bot?  # protect own messages
        bot.send_message(event.channel.id, message[:message])
      else
        bot.send_message(channel.id, "A message by #{member.name} was deleted in ##{event.channel.name}")
      end
    end
  end
end
