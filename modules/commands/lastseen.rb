require 'bot-feature.rb'


class LastSeenFeature < BotFeature
  def register_handlers(bot, scheduler)
    #TODO: Cache
    bot.add_help({
      command: ["lastseen", "seen"],
      short_help: %{!lastseen/!seen: look up when someone last spoke.},
      long_help: %{Look up when a user last spoke.
Usage:
  **!seen** @<mention>: Look up when this person last spoke. This MUST be a mention.
}
    })

    bot.message(contains: /^\!(last)?seen\s+/) do |event|
      options = parse_args(event.message.to_s)

      if event.message.mentions.size == 0
        event.respond("You must have a mention in the command (ie !seen @user).")
        next
      end

      mentions = event.message.mentions
      user = User.where(discord_id: mentions.first.id)
      if user.size == 0
        event.respond("There is no mention in your command.")
        next
      end

      messages = Message.where(user: user).order("created_at DESC")
      if messages.size == 0
        event.respond("I've never seen that person speak.")
        next
      end

      event.respond("I last saw #{mentions.first.username} on #{messages.first.created_at.getlocal.to_formatted_s(:local_ordinal)}")
    end
  end
end
