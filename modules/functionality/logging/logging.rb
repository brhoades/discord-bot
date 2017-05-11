require 'bot-feature.rb'

class LoggingFeature < BotFeature
  def register_handlers(bot, scheduler)
    bot.message do |event|
      # Stores the message by getting it
      # DEPRECATED
      Message.ensure(event.message)
    end

    bot.message_delete do |event|
      message = Message.where(discord_id: event.id).first

      next if not message
      puts "\"#{message.id}: #{message.ignore}, #{message.text}\""

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

      if message.text =~ /\#no(delete|rm|del)/ && !message.ignore
        if message.text.size + member.name.size + 2 > 500 || message.text =~ /^#{member.name}:/
          bot.send_message(event.channel.id, message.text)
        else
          bot.send_message(event.channel.id, "#{member.name}: #{message.text}")
        end
      end

      if event.channel.name.to_s == "logs" and member.current_bot?  # protect own messages
        bot.send_message(event.channel.id, message.text)
      else
        bot.send_message(channel.id, "A message by #{member.name} was deleted in ##{event.channel.name}")
      end
    end
  end
end
