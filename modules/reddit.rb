class RedditFeature < BotFeature
  def register_bot_handlers(bot)
    bot.message(contains: /m\.reddit\.com/) do |event|
      message = event.message.to_s.gsub /m\.reddit\.com/, "reddit.com"
      event.message.delete

      event.respond "#{event.message.author.username}: #{message}"
    end
  end
end
