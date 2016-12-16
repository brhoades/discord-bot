require 'net/http'
require 'json'
require_relative '../bot-feature.rb'

$ignore = []

class GiphyFeature < BotFeature
  def initialize
    @giphys = {}
  end

  def register_handlers(bot, scheduler)
    bot.message(contains: /^[!\/]giphy/) do |event|
      $ignore << event.message.id
      response = get_random_url(event.message, event.message.author.username, event.channel.name =~ /giphy_nsfw/)
      author = event.message.author.username
      @giphys[author] = {
        message: event.respond(response),
        original: event.message.to_s,
        rerolls: 0
      }

      event.message.delete
    end

    bot.message(contains: /^[!\/]reroll/) do |event|
      $ignore << event.message.id
      author = event.message.author.username
      event.message.delete
      if @giphys.has_key? author
        response = get_random_url(@giphys[author][:original], author)
        $ignore << @giphys[author][:message].id
        @giphys[author][:message].delete
        @giphys[author][:rerolls] += 1
        message = get_random_url(@giphys[author][:original], author, event.channel.name =~ /giphy_nsfw/, extra="(rerolls: #{@giphys[author][:rerolls]})")
        @giphys[author][:message] = event.respond(message)
      end
    end
  end

  private

  def get_random_url(event_message, author, nsfw=false, extra="")
    original = event_message.to_s
    original.gsub! /\&/, ""
    message = original.split(/ /)
    message.delete_at 0

    url = "http://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC&tag=#{message.join("+")}"
    if not nsfw
      url += "&rating=pg-13"
    end 

    url = URI(url)
    response = JSON.parse(Net::HTTP.get(url))


    if response["data"] and response["data"].is_a? Hash
      if response["data"].has_key?('url')
        url = response["data"]["url"]
        "#{author}: #{original} #{extra}\n#{url}"
      end
    else
      "#{author}: #{original} (**no matches**)"
    end
  end
end
