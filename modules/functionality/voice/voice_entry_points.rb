require 'digest'

require_relative 'voice_message.rb'


module VoiceEntryPoints
  def play_file(event)
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
      return
    end
    filename.delete

    if not @voice_queue.has_key? event.server
      @voice_queue[event.server] = []
    end


    message = VoiceMessage.new(event.author, event.author.voice_channel, tempfile)
    message.delete = true
    message.volume = volume

    @voice_queue[event.server] << message
  end

  # Actually send a message. Cache the mp3 in tmp.
  # TODO: make cache optional and give it a sub directory.
  def send_message(bot, server, channel, user, message)
    lang = @config[:lang]
    name = Digest::SHA256.hexdigest (message.to_s + @config[:lang])
    if !Dir.exists?(@config[:cache_directory])
      `mkdir -p #{@config[:cache_directory]}`
    end

    file = File.join(@config[:cache_directory], "#{name}")

    if !File.exists?("#{file}.mp3")
      File.write "#{file}.txt", message
      `perl simple-google-tts/speak.pl ja "#{file}.txt" "#{file}.mp3"`
      `rm #{file}.txt`
    end

    if !@voice_queue.has_key?(server)
      @voice_queue[server] = []
    end

    if @voice_queue[server].select { |v| v[:owner] == user }.size >= @QUEUE_SIZE
      puts "Limit reached for \"#{user.username}\" on \"#{channel}\""
      return
    end

    @voice_queue[server] << VoiceMessage.new(user, channel, "#{file}.mp3")
  end
end
