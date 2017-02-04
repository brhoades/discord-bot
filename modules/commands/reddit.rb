require_relative '../../bot-feature.rb'

class RandomFeatures < BotFeature
  def register_handlers(bot, scheduler)
    bot.message(contains: /bees(\W|$)/) do |event|
      event.respond "https://media.giphy.com/media/dcubXtnbck0RG/giphy.gif"
    end

    bot.message(contains: /m\.(imgur\.com|reddit\.com)/) do |event|
      message = event.message.to_s
      message.sub! /m\./, ""
      event.message.delete
      event.respond "#{event.author.username.to_s}: #{message}"
    end
  end
end
