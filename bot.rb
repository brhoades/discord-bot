require 'discordrb'
require 'json'
require 'digest'
require 'rufus-scheduler'
require_relative 'bot-feature.rb'

# https://discordapp.com/oauth2/authorize?client_id=251052745790849026&scope=bot&permissions=70282304
$voice = {}
$voice_queue = {}
$QUEUE_SIZE = 3

def handle_message bot
  return if $voice_queue.size == 0
  $voice_queue.each do |k,v|
    next if v.size == 0
    voice_bot = nil
    if bot.voices.has_key? k.id
      voice_bot = bot.voices[k.id]
    end
    return if voice_bot and voice_bot.playing?
  
    message = v.pop
    voice_bot = bot.voice_connect message[:channel]
    voice_bot.play_file message[:file]
    voice_bot.stop_playing
  end
end

def send_message(bot, server, channel, message)
  name = Digest::SHA256.hexdigest message
  file = "/tmp/#{name}"
  if !File.exists? "#{file}.txt" or !File.exists? "#{file}.mp3"
    File.write("#{file}.txt", message)
    `perl simple-google-tts/speak.pl en "#{file}.txt" "#{file}.mp3"`
  end

  if !$voice_queue.has_key? server
    $voice_queue[server] = SizedQueue.new($QUEUE_SIZE)
  end

  $voice_queue[server] << {
    file: "#{file}.mp3",
    channel: channel
  }
end

def process_voice_state(bot, server, channel, user)
  return if user.username == bot.profile.username

  if !$voice.has_key? server
    $voice[server] = {} 
  end

  if channel and !$voice[server].has_key? channel
    $voice[server][channel] = []
  end

  $voice[server].each do |k,v|
    if v.include? user and k != channel
      v.delete user
      if v.size > 0
        # notify users, this isn't just an initial load.
        send_message bot, server, k, "#{user.username} left"
      end
    end
  end

  if channel and !$voice[server][channel].include? user
    $voice[server][channel] << user
    if $voice[server][channel].length > 0 
      send_message bot, server, channel, "#{user.username} joined"
    end
   end
end

bot = Discordrb::Bot.new token: ENV["BOT_TOKEN"], client_id: 251052745790849027, parse_self: true
scheduler = Rufus::Scheduler.new

# Load modules
current_path = File.expand_path(".")
Dir["#{current_path}/modules/*.rb"].each do |file|
  require file
end

BotFeature.descendants.each do |feature_class|
  feature = feature_class.new
  feature.register_schedules(scheduler)
  feature.register_bot_handlers(bot)
  puts "Registered Feature \"#{feature_class}\""
end

scheduler.every '1s' do
  handle_message bot if $voice_queue.size > 0
end


bot.voice_state_update do |event|
  process_voice_state(bot, event.server, event.channel, event.user)
end

bot.run

#TODO: Split into separate files for each command
#TODO: Create module structure.
#TODO: Add hooks for each command module. before_run after_run, etc.
#TODO: store user stats... number of words, number of lines, images, links, most popular phrases, etc. STore it all.
