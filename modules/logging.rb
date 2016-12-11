require_relative '../bot-feature.rb'

$messages = {}

class LoggingFeature < BotFeature
  def register_handlers(bot, scheduler)
    bot.message_delete do |event|
      next if $ignore.include?(event.id)
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
