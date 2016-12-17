require_relative '../../bot-feature.rb'

class RedditFeature < BotFeature
  def register_handlers(bot, scheduler)
    bot.message(contains: /m\.reddit\.com/) do |event|
      message = event.message.to_s.gsub /m\.reddit\.com/, "reddit.com"
      event.message.delete

      event.respond "#{event.message.author.username}: #{message}"
    end
  end
end
