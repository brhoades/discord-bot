require 'discordrb'
require 'net/http'
require 'json'

# current_path = File.expand_path("../", __FILE__)
# Dir["#{current_path}/**/*.rb"].each { |file| require file }

# https://discordapp.com/oauth2/authorize?client_id=251052745790849026&scope=bot&permissions=70282304
$ignore = []
$messages = {}

bot = Discordrb::Bot.new token: ENV["BOT_TOKEN"], client_id: 251052745790849027, parse_self: true

bot.message(contains: /^[!\/]giphy/) do |event|
  original = event.message.to_s
  message = original.split(/ /)
  message.delete_at 0
  $ignore << event.message.id
  author = event.message.author

  if author.nick
    author = author.nick.to_s
  else
    author = author.username.to_s
  end
  event.message.delete

  url = URI("http://api.giphy.com/v1/gifs/random?api_key=dc6zaTOxFJmzC&rating=pg-13&tag=#{message.join("+")}")
  response = JSON.parse(Net::HTTP.get(url))
  if response["data"].has_key?('url')
    url = response["data"]["url"]
    event.respond("#{author}: #{original}\n#{url}")
  end
end

bot.message_delete do |event|
  channel = bot.find_channel("logs")[0]
  if $ignore.include?(event.id)
    return
  end

  if $messages.has_key?(event.id)
    if $messages[event.id].has_key?(:content) and event.channel.name.to_s == "logs"
      bot.send_message(event.channel.id, $messages[event.id][:content])
    else
      bot.send_message(channel.id, "A message by #{$messages[event.id][:user]} was deleted in ##{event.channel.name}")
    end
  else
    bot.send_message(channel.id, "A message was deleted in ##{event.channel.name}")
  end
end

bot.message do |event|
  $messages[event.message.id] = {
    user: event.message.author.username.to_s,
    timestamp: event.timestamp
  }

  if event.message.author.username == bot.profile.username
    $messages[event.message.id][:content] = event.message.content.to_s
  end
end

bot.run

#TODO: Split into separate files for each command
#TODO: Create module structure.
#TODO: Add hooks for each command module. before_run after_run, etc.
#TODO: store user stats... number of words, number of lines, images, links, most popular phrases, etc. STore it all.
