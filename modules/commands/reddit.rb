require_relative '../../bot-feature.rb'

class RandomFeatures < BotFeature
  def register_handlers(bot, scheduler)
    bot.message(contains: /bee\w/) do |event|
      event.respond "https://media.giphy.com/media/dcubXtnbck0RG/giphy.gif"
    end
  end
end
