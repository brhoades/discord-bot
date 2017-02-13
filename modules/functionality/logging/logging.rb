require 'sequel'

require_relative '../../../bot-feature.rb'
require_relative '../../../modelhandlers.rb'

class LoggingFeature < BotFeature
  include ModelHandlers

  def register_handlers(bot, scheduler)
    bot.message do |event|
      # Stores the message by getting it
      # DEPRECATED
      get_message(bot, event.message, event.server)

      Message.ensure(event.message)
    end

    bot.message_delete do |event|
      message = Message.where(discord_id: event.id).first

      puts "\"#{message}: #{message.ignore}, #{message.text}\""
      next if not message

      message.reload
      message.deleted = true
      message.save!
      next if message.ignore

      channel = bot.find_channel("logs", event.channel.server.name)

      if channel.size == 0
        puts "#logs not found on #{event.channel.server.name}."
        next
      end
      channel = channel.first
      member = bot.member(event.channel.server, message.user.discord_id)

      if event.channel.name.to_s == "logs" and member.current_bot?  # protect own messages
        bot.send_message(event.channel.id, message[:message])
      else
        bot.send_message(channel.id, "A message by #{member.name} was deleted in ##{event.channel.name}")
      end
    end
  end
end
