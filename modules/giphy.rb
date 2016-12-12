require 'net/http'
require 'json'
require_relative '../bot-feature.rb'

$ignore = []
$giphys = {}

class GiphyFeature < BotFeature
  def register_handlers(bot, scheduler)
    bot.message(contains: /^[!\/]giphy/) do |event|
      $ignore << event.message.id
      response = get_random_url(event.message, event.message.author.username)
      author = event.message.author.username
      $giphys[author] = {
        message: event.respond(response),
        original: event.message.to_s
      }

      event.message.delete
    end

    bot.message(contains: /^[!\/]reroll/) do |event|
      $ignore << event.message.id
      author = event.message.author.username
      event.message.delete
      if $giphys.has_key? author
        response = get_random_url($giphys[author][:original], author)
        $giphys[author][:message].delete
        $giphys[author][:message] = event.respond(get_random_url($giphys[author][:original], author))
      end
    end
  end

  private

  def get_random_url(event_message, author)
    original = event_message.to_s
    original.gsub! /\&/, ""
    message = original.split(/ /)
    message.delete_at 0

    url = URI("http://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC&rating=pg-13&tag=#{message.join("+")}")
    response = JSON.parse(Net::HTTP.get(url))
    if response["data"].has_key?('url')
      url = response["data"]["url"]
      "#{author}: #{original}\n#{url}"
    end
  end
end
