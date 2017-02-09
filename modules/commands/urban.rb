require 'rest-client'
require 'htmlentities'

require 'bot-feature.rb'


class UrbanDictionaryFeature < BotFeature
  def register_handlers(bot, scheduler)
    #TODO: Cache
    bot.add_help({
      command: ["urban", "ud"],
      short_help: %{!urban/!ud: urban dictionary definition lookup.},
      long_help: %{Urban Dictionary definition lookup for a term.
Usage:
  **!urban** <term>: Look up a term and return the first result.
}
    })

    bot.message(contains: /\!(urban|ud)\s+/) do |event|
      options = parse_args event.message.to_s

      query = HTMLEntities.new.encode(options[:target], :basic, :named, :decimal)

      response = get_data "term=#{query}"
      next response["error"] if response.has_key? "error"

      definitions = response["list"]

      next "No results" if definitions.size == 0

      offset = (options.dig(:args, "offset") || 1).to_i
      defin = definitions[offset]

      event.respond %{\
**#{defin["word"]}** by *#{defin["author"]}* (#{offset+1} of #{definitions.size})
#{defin["thumbs_up"]} :+1:\t#{defin["thumbs_down"]} :-1:

**#{defin["word"]}**:
#{defin["definition"]}

**Example**: #{defin["example"]}

#{defin["permalink"]}
}
    end
  end

  # Assumes args is a preformatted query to tack on to the end of our urbandictionary API.
  def get_data(args)
    url = "https://api.urbandictionary.com/v0/define?#{args}"

    begin
      res = RestClient.get(url)
    rescue RestClient::Exception => e
      return {"error" => "Error: #{e.to_s}\nWith URL: #{url}"}
    end

    JSON.load res.body
  end
end
