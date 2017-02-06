require 'digest'
require 'open3'
require 'pty'

require_relative 'voice_message.rb'


module VoiceEntryPoints
  def play_web_address(event)
    msg = event.message.to_s.split(/\s+/)
    file = msg[1]
    volume = @config[:default_play_volume]
    if msg.size > 1
      volume = msg[2]
    end

    # NOTE: must have youtube-dl/python3
    if file =~ /youtube.com/i
      filename = get_yt_video_audio file, event
      return if not filename
      play_file filename, event, volume
    else
      download_and_transcode_file file, event, volume
    end

  end

  def get_yt_video_audio(url, event=nil)
    #TODO: not this

    tempfile = `tempfile -s .mp3`.gsub(/\n/, "")
    `rm -f #{tempfile}`
    command = "python3 -m youtube_dl --no-playlist --max-filesize=#{@config[:max_yt_filesize]} --audio-format mp3 --extract-audio -o \"#{tempfile}\" \"#{url}\""
    contents = "Beginning...\n\n"
    message = event.respond contents
    PTY.spawn(command) do |stdout, stdin, pid|
      begin
        # Do stuff with the output here. Just printing to show it works
        stdout.each do |l|
          contents += "#{l}"
          message.edit contents
        end
        message.delete
      rescue Errno::EIO
      end
    end

    tempfile
  end
  def download_and_transcode_file(file, event=nil, volume=nil)
    filename = Tempfile.new('input')
    filename.write(open(file) { |f| f.read })
    filename.close
    tempfile = `tempfile -s .wav`.gsub(/\n/, "")

    #:TODO: popen3
    system("ffmpeg -y -loglevel panic -i \"#{filename.path}\" \"#{tempfile}\"")
    if $? != 0
      filename.delete
      system("rm -f \"#{tempfile}\"")
      puts "Error creating #{tempfile}"
      return "Error creating #{tempfile}"
    end
    filename.delete

    if event and volume
      play_file(file, event, volume)
    end
  end

  def play_file(file, event, volume=@config[:default_play_volume])

    if not @voice_queue.has_key? event.server
      @voice_queue[event.server] = []
    end

    message = VoiceMessage.new(event.author, event.author.voice_channel, file)
    message.delete = true
    message.volume = volume

    @voice_queue[event.server] << message
  end

  # Actually send a message. Cache the mp3 in tmp.
  # TODO: make cache optional and give it a sub directory.
  def send_message(bot, server, channel, user, message)
    lang = @config[:lang]
    name = Digest::SHA256.hexdigest (message.to_s + lang)
    message.gsub!(/^\s+/, "")
    if !Dir.exists?(@config[:cache_directory])
      system("mkdir -p \"#{@config[:cache_directory]}\"")
    end

    file = File.join(@config[:cache_directory], "#{name}")

    # popen3
    if !File.exists?("#{file}.mp3")
      File.write "#{file}.txt", message

      Open3.popen3("perl", "simple-google-tts/speak.pl", lang, "#{file}.txt", "#{file}.mp3") do |stdin, stdout, stderr, thread|
        error = stderr.read
        message = stdout.read
        if thread.value != 0
          # TODO: Billbot tries to log own DMs and enters a loop
          # user.pm "Error writing a message for you. Please report this to an admin."
          # user.pm "STDOUT\n```#{message}```"
          # user.pm "STDERR\n```#{error}```"
          puts "Error writing message"
          puts "STDOUT\n#{message}\n\nSTDERR\n#{error}\n\n"

          system("rm -f \"#{file}.txt\"")
          return
        end
      end

      system("rm \"#{file}.txt\"")
    end

    if !@voice_queue.has_key?(server)
      @voice_queue[server] = []
    end

    if @voice_queue[server].select { |v| v.owner == user }.size >= @QUEUE_SIZE
      puts "Limit reached for \"#{user.username}\" on \"#{channel}\""
      return
    end

    message = VoiceMessage.new(user, channel, "#{file}.mp3")
    message.volume = 1.0
    @voice_queue[server] << message
  end
end
