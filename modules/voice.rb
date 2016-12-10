require 'digest'

require_relative '../bot-feature.rb'

$voice = {}
$voice_queue = {}

# Announce users joining and leaving channels.
class VoiceFeatures < BotFeature
  def register_bot_handlers(bot)
    bot.voice_state_update do |event|
      process_voice_state(bot, event.server, event.channel, event.user)
    end
  end

  def register_schedules(bot, scheduler)
    scheduler.every '1s' do
      process_voice_queue bot if $voice_queue.size > 0
    end
  end

  private

  # Called every second by rufus to process our voice queue.
  # If the bot isn't speaking on a server,
  def process_voice_queue(bot)
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
      voice_bot.stop_playing  # if we don't stop playing, even though play_file is blocking, playing?
                              # will continue to return true.
    end
  end

  # Actually send a message. Cache the mp3 in tmp.
  # TODO: make cache optional and give it a sub directory.
  def send_message(bot, server, channel, message)
    name = Digest::SHA256.hexdigest message
    file = "/tmp/#{name}"
    if !File.exists? "#{file}.txt" or !File.exists? "#{file}.mp3"
      File.write("#{file}.txt", message)
      `perl simple-google-tts/speak.pl en "#{file}.txt" "#{file}.mp3"`
      `rm #{file}.txt`
    end

    if !$voice_queue.has_key? server
      $voice_queue[server] = SizedQueue.new($QUEUE_SIZE)
    end

    $voice_queue[server] << {
      file: "#{file}.mp3",
      channel: channel
    }
  end

  # Called on a voice event. If it's not us, we internally
  # update our voice session tracking.
  # TODO: do this on bot start.
  # TODO: decouple from sending messages
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
end

