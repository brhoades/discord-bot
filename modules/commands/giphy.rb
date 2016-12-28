require 'net/http'
require 'json'
require_relative '../../bot-feature.rb'

$ignore = []

class GiphyFeature < BotFeature
  def initialize
    @giphys = {}
    @args = {
      
      toplevel: {
        random: {
          description: "Choose a random giphy. A query can be included to filter the overall pool.",
          paramter: "random",
          base_url: "https://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC",
          accepts: [nil, "tags"]
        },
        search: {
          description: "Search for a giphy, returning consistent results. A query is required.",
          base_url: "https://api.giphy.com/v1/gifs/search?api_key=dc6zaTOxFJmzC",
          parameter: "search",
          requires: ["q"],
          accepts: ["offset"]
        }
      },
      modifiers: {
        "offset": {
          accepts: /^[0-9]+$/
        }
      }
    }
  end

  def register_handlers(bot, scheduler)
    bot.message(contains: /^[!\/]giphy/) do |event|
      parse_command event.message.to_s
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

  # Parse the command into the command (!(command)) arguments (-bla) and the query.
  def parse_command(original)
    url = ""
    bits = original.split(/ /)
    args = []
    query = []

    command = bits[0]
    bits.delete_at 0

    bits.each do |arg|
      if arg =~ /-[A-Za-z]/ and query.size == 0
        args << arg
      else
        query << arg
      end
    end

    puts url
    puts "args: #{args}"
    puts "query: #{query}"

    url = build_url command, args, query
  end

  def build_url(command, args, query)

  end

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
