module VoiceProcessing
  # Called every second by rufus to process our voice queue.
  # If the bot isn't speaking on a server,
  def process_voice_queue(bot)
    return if @voice_queue.size == 0

    @voice_queue.each do |k,v|
      next if v.size == 0
      voice_bot = nil
      if bot.voices.has_key? k.id
        voice_bot = bot.voices[k.id]
      end

      return if voice_bot and voice_bot.playing?

      message = v.pop

      # Check cached file exists
      if not File.exist?(message.file)
        puts "Unknown file #{message.file}"
        next
      end

      voice_bot = bot.voice_connect message.channel

      # Adjust volume
      voice_bot.filter_volume = message.volume

      voice_bot.play_file message.file
      voice_bot.stop_playing  # if we don't stop playing, even though play_file is blocking, playing?
                              # will continue to return true.

      if !@config[:cache] or message.delete?
        `rm -f #{message.file}`
      end
    end
  end
end
