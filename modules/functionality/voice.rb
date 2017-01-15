require 'digest'
require 'tempfile'
require 'open-uri'

require_relative '../../bot-feature.rb'

$voice = {}
$voice_queue = {}
$QUEUE_SIZE = 3

# Announce users joining and leaving channels.
class VoiceFeatures < BotFeature
  def load(bot)
    config = bot.get_config_for_module(__FILE__)
    @config = {
      cache: true,
      cache_directory: "/tmp/",
      authorized_play_users: [],  # * allows all
      default_play_volume: 0.05,
      default_volume: 1.0
    }

    bot.map_config(config, @config)
  end

  def register_handlers(bot, scheduler)
    bot.voice_state_update do |event|
      process_voice_state(bot, event.server, event.channel, event.user)
    end

    bot.message(contains: /^\!play .+/) do |event|
      authed = false
      @config[:authorized_play_users].each do |name|
        if event.author.username.to_s =~ /^#{name}/i
          authed = true
        end
      end

      next "!giphy unauthorized" unless authed

      msg = event.message.to_s.split(/\s+/)
      file = msg[1]

      # Default volume is fairly quiet
      volume = @config[:default_play_volume]
      if msg.size == 3
        volume = msg[2].to_f
      end

      filename = Tempfile.new('input')
      filename.write(open(file) { |f| f.read })
      filename.close
      tempfile = `tempfile -s .wav`.gsub(/\n/, "")

      system("ffmpeg -y -loglevel panic -i #{filename.path} #{tempfile}")
      if $? != 0
        puts "Error when transcoding #{msg[1]}"
        filename.delete
        `rm -f #{tempfile}`
        next
      end
      filename.delete

      if not $voice_queue.has_key? event.server
        $voice_queue[event.server] = []
      end

      $voice_queue[event.server] << {
        file: tempfile,
        channel: event.author.voice_channel,
        volume: volume
      }
    end

    scheduler.every '1s' do
      begin
        process_voice_queue bot if $voice_queue.size > 0
      rescue Exception => e
        puts "Error in process voice queue #{e.to_s}"
      end
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

      # Check cached file exists
      if not File.exist?(message[:file])
        puts "Unknown file #{message[:file]}"
        next
      end

      voice_bot = bot.voice_connect message[:channel]

      # Adjust volume
      if message.has_key?(:volume)
        voice_bot.filter_volume = message[:volume].to_f
      else
        voice_bot.filter_volume = @config[:default_volume]
      end

      voice_bot.play_file message[:file]
      voice_bot.stop_playing  # if we don't stop playing, even though play_file is blocking, playing?
                              # will continue to return true.

      if !@config[:cache]
        `rm #{message[:file]}`
      end
    end
  end

  # Actually send a message. Cache the mp3 in tmp.
  # TODO: make cache optional and give it a sub directory.
  def send_message(bot, server, channel, message)
    name = Digest::SHA256.hexdigest message
    if !Dir.exists?(@config[:cache_directory])
      `mkdir -p #{@config[:cache_directory]}`
    end

    file = File.join(@config[:cache_directory], "#{name}")

    if !File.exists?("#{file}.mp3")
      File.write("#{file}.txt", message)
      `perl simple-google-tts/speak.pl en "#{file}.txt" "#{file}.mp3"`
      `rm #{file}.txt`
    end

    if !$voice_queue.has_key?(server)
      $voice_queue[server] = Queue.new
    end

    return if $voice_queue[server].length >= $QUEUE_SIZE

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
    return if user.current_bot?

    if !$voice.has_key? server
      $voice[server] = {} 
    end

    if channel and !$voice[server].has_key? channel
      $voice[server][channel] = []
    end

    name = user.username.gsub /[0-9]+$/, ""

    $voice[server].each do |k,v|
      if v.include? user and k != channel
        v.delete user
        if v.size > 1
          # notify users, this isn't just an initial load.
          send_message bot, server, k, "#{name} left"
        end
      end
    end

    if channel and !$voice[server][channel].include? user
      $voice[server][channel] << user
      total_server = $voice[server].map { |l| l.size }.reduce(0, :+)
      if total_server == 1 and $voice[server][channel].size == 1
        send_message bot, server, channel, "You look nice today, #{name}"
      elsif $voice[server][channel].length >= 2 
        send_message bot, server, channel, "#{name} joined"
      end
     end
  end
end

