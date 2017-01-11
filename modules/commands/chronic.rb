require 'chronic'

require_relative '../../bot-feature.rb'
require_relative '../../modelhandlers.rb'

class ChronicFeature < BotFeature
  def load(bot)
    @primary_regex = /^\!remindme( on|at)? (?<timerange>.+) (that|to) (?<reminder>.+)$/
  end

  def register_handlers(bot, scheduler)
    bot.message(contains: @primary_regex) do |event|
      next if event.author.current_bot?
      if not can_create_reminder?(bot, event.message.author)

        event.respond("!giphy not gonna happen")
        next
      end


      matches = @primary_regex.match(event.message.to_s)
      timerange, reminder = matches[:timerange], matches[:reminder]
      puts "timerange: #{timerange} (parsed: #{Chronic.parse(timerange)})"
      puts "reminder: #{reminder}"
      timerange = Chronic.parse(timerange)

      if timerange == nil
        event.respond("Could not parse provided timerange '#{timerange}'")
        next
      end

      if create_reminder(bot, timerange, event.message.author.mention, reminder, event.message)
        event.respond "Created reminder for #{event.message.author.mention} which will fire on #{timerange}."
      else
        event.respond "Error creating reminder."
        next
      end
    end

    scheduler.every '10s' do
      events = bot.db[:chronic].where('time <= ?', Time.now).all
      next if events.length == 0

      events.each do |cron|
        channel = bot.db[:channels].where(id: cron[:channel_id]).first

        if channel == nil 
          # Remove event still
          puts "Error finding channel for event."
        else
          bot.send_message(channel[:discord_id], "#{cron[:target]}: #{cron[:message]}")
        end

        bot.db[:chronic].where(id: cron[:id]).delete
      end
    end
  end

  private
  include ModelHandlers

  def can_create_reminder?(bot, discord_user)
    user = get_user(bot, discord_user)
    reminders = bot.db[:chronic].where(user_id: user[:id]).all

    return reminders.length < 10
  end

  # Create a model handler entry on our table
  def create_reminder(bot, timerange, target, reminder, message)
    user = get_user(bot, message.author)
    server = get_server(bot, message.channel.server)
    channel = get_channel(bot, message.channel)

    bot.db[:chronic].insert(user_id: user[:id],
                            channel_id: channel[:id],
                            server_id: server[:id],
                            time: timerange,
                            target: target,
                            reminder: reminder) != nil
  end
end
