require 'net/http'
require 'json'
require_relative '../bot-feature.rb'

$ignore = []

class GiphyFeature < BotFeature
  def register_bot_handlers(bot)
    bot.message(contains: /^[!\/]giphy/) do |event|
      event.respond get_random_url(event.message)
    end
  end

  private

  def get_random_url(event_message)
    original = event_message.to_s
    original.gsub! /\&/, ""
    message = original.split(/ /)
    message.delete_at 0
    $ignore << event_message.id
    author = event_message.author

    if author.nick
      author = author.nick.to_s
    else
      author = author.username.to_s
    end
    event_message.delete

    url = URI("http://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC&rating=pg-13&tag=#{message.join("+")}")
    response = JSON.parse(Net::HTTP.get(url))
    if response["data"].has_key?('url')
      url = response["data"]["url"]
      "#{author}: #{original}\n#{url}"
    end
  end
end
