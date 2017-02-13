require 'net/http'
require 'json'

require 'bot-feature.rb'

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
    bot.add_help({
      command: ["giphy", "gp", "reroll"],
      short_help: %{!giphy/!gp/!reroll: Giphy Image Search},
      long_help: %{Giphy Image Search
Usage:
  **!giphy** *<tag>*: randomly look up a a Giphy filtering by a tag.
  **NOTE: If a channel name has nsfw in it, this lookup can return unrated content.**
  **!giphy** -exact *<query>*: look up a Giphy by a query and return the best result.

  **!reroll**: reroll a random Giphy and get a fresh one.
}
    })
    bot.message(contains: /^[!\/](giphy|gp)\s+/) do |event|
      parse_command event.message.to_s
      message = Message.ensure(event.message)
      message.ignore = true
      message.save!

      response = get_random_url(event.message, event.message.author.username, event.channel.name =~ /nsfw/)
      author = event.message.author.username
      @giphys[author] = {
        message: event.respond(response),
        original: event.message.to_s,
        rerolls: 0
      }

      event.message.delete
    end

    bot.message(contains: /^[!\/]reroll$/) do |event|
      message = Message.ensure(event.message)
      message.ignore = true
      message.save!

      author = event.message.author.username
      if @giphys.has_key? author
        response = get_random_url(@giphys[author][:original], author)
        $ignore << @giphys[author][:message].id
        @giphys[author][:message].delete
        @giphys[author][:rerolls] += 1
        message = get_random_url(@giphys[author][:original], author, event.channel.name =~ /nsfw/, extra="(rerolls: #{@giphys[author][:rerolls]})")
        @giphys[author][:message] = event.respond(message)

        response = Message.ensure(@giphys[author][:message])
        response.ignore = true
        response.save!
      end

      event.message.delete
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

    url = build_url command, args, query
  end

  def build_url(command, args, query)

  end

  def get_random_url(event_message, author, nsfw=false, extra="")
    message = event_message.to_s.dup.gsub(/\&/, "").split(/ /)
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
        "#{author}: #{event_message.to_s} #{extra}\n#{url}"
      end
    else
      "#{author}: #{event_message.to_s} (**no matches**)"
    end
  end
end
