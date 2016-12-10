require 'discordrb'
require 'net/http'
require 'json'
require 'digest'

# current_path = File.expand_path("../", __FILE__)
# Dir["#{current_path}/**/*.rb"].each { |file| require file }

# https://discordapp.com/oauth2/authorize?client_id=251052745790849026&scope=bot&permissions=70282304
$ignore = []
$messages = {}
$voice = {}

def send_message(bot, server, channel, message)
  voice_bot = bot.voice_connect channel
  name = Digest::SHA256.hexdigest message
  file = "/tmp/#{name}"
  if !File.exists? "#{file}.txt" and !File.exists? "#{file}.mp3"
    File.write("#{file}.txt", message)
    `perl simple-google-tts/speak.pl en "#{file}.txt" "#{file}.mp3"`
  end

  voice_bot.play_io File.open("#{file}.mp3")
end

def process_voice_state(bot, server, channel, user)
  return if user.username == bot.profile.username

  if !$voice.has_key? server
    $voice[server] = {} 
  end

  if channel and !$voice[server].has_key? channel
    $voice[server][channel] = []
  end

  if channel
    puts user.username, channel.name
  else
    puts user.username, " left"
  end

  $voice[server].each do |k,v|
    if v.include? user and k != channel
      v.delete user
      if $voice[server].size > 0
        # notify users, this isn't just an initial load.
        send_message bot, server, k, "#{user.username} left"
        puts user.username, " left"
      end
    end
  end

  if channel and !$voice[server][channel].include? user
    $voice[server][channel] << user
    if $voice[server][channel].length > 0 
      send_message bot, server, channel, "#{user.username} joined"
      puts user.username, channel.name
    end
   end
end

bot = Discordrb::Bot.new token: ENV["BOT_TOKEN"], client_id: 251052745790849027, parse_self: true

bot.message(contains: /^[!\/]giphy/) do |event|
  original = event.message.to_s
  original.gsub! /\&/, ""
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

bot.voice_state_update do |event|
  process_voice_state(bot, event.server, event.channel, event.user)
end

bot.run

#TODO: Split into separate files for each command
#TODO: Create module structure.
#TODO: Add hooks for each command module. before_run after_run, etc.
#TODO: store user stats... number of words, number of lines, images, links, most popular phrases, etc. STore it all.
