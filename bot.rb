require 'discordrb'
require 'giphy'
require_relative 'gta.rb'

# https://discordapp.com/oauth2/authorize?client_id=251052745790849026&scope=bot&permissions=70282304
$ignore = []

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
  $ignore << event.message.id
  author = event.message.author
  if author.nick
    author = author.nick.to_s
  else
    author = author.username.to_s
  end
  event.message.delete

  if message.length == 0
    event.respond(Giphy.random().url.to_s + " (#{author})")
    return
  end

  results = Giphy.random(message.join(" "))
  if results
    event.respond(results.url.to_s + " (#{author})")
  end
end

bot.message_delete do |event|
  channel = bot.find_channel("logs")[0]
  if !$ignore.include?(event.id)
    bot.send_message channel.id, "A message was deleted in ##{event.channel.name}"
  end
end

bot.run

#TODO: Split into separate files for each command
#TODO: Create module structure.
#TODO: Add hooks for each command module. before_run after_run, etc.
#TODO: store user stats... number of words, number of lines, images, links, most popular phrases, etc. STore it all.
