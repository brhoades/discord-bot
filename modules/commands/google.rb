require 'nokogiri'
require 'open-uri'
require 'uri'

require_relative '../../bot-feature.rb'


module GoogleSearchAPI
  def get_first_search(query)
    clean_query = URI.escape(query.gsub(/\s+/, "+"))

    url = "https://google.com/search?q=#{clean_query}"
    contents = open(url).read
    html = Nokogiri::HTML(contents)

    html.search("cite").first.inner_text
  end

  def get_first_image
    clean_query = URI.escape(query.gsub(/\s+/, "+"))

    url = "https://www.google.com/search?tbm=isch&q=#{clean_query}"
    contents = open(url).read
    html = Nokogiri::HTML(contents)
  end
end

class GoogleFeature < BotFeature
  include GoogleSearchAPI

  def initialize
  end

  def load(bot)
  end

  def register_handlers(bot, scheduler)
    bot.add_help({
      command: ["g", "gi", "google"],
      short_help: %{!g/!gi/!google: Do Google searches and return results.},
      long_help: %{Google Search
Usage:
  **!g(oogle)** <query>: returns the first Google search result.
  **!gi** <query>: returns the first image in a Google Images search.
}
    })

    bot.message(contains: /^[!\/]g(oogle)?\s/) do |event|
      msg = event.message.to_s.split(/\s+/)
      msg.delete_at 0
      query = msg.join(" ")

      event.respond get_first_search query
    end

    bot.message(contains: /^[!\/]gi\s/) do |event|
      msg = event.message.to_s.split(/\s+/)
      msg.delete_at 0
      query = msg.join(" ")

      event.respond get_first_image query
    end
  end
end
