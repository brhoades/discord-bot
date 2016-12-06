require 'discordrb'
require 'giphy'
require_relative 'gta.rb'

bot = Discordrb::Bot.new token: ENV["BOT_TOKEN"], client_id: 251052745790849027
Giphy::Configuration.configure do |config|
  config.api_key = "dc6zaTOxFJmzC"
end

bot.message(with_text: 'Ping!') do |event|
  event.respond 'Pong!'
end

bot.message(with_text: 'gta') do |event|
end

bot.message(contains: /^[!\/]giphy/) do |event|
  message = event.message.to_s.split(/ /)
  message.delete_at 0
  if message.length == 0
    return event.respond Giphy.random().url
  end

  results = Giphy.random(message.join(" "))
  if results
    event.respond results.url
  else
    event.respond "No results"
  end
end

bot.run
