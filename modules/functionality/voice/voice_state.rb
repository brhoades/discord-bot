module VoiceState
  # Called on a voice event. If it's not us, we internally
  # update our voice session tracking.
  # TODO: do this on bot start.
  # TODO: decouple from sending messages
  def process_voice_state(bot, server, channel, user)
    return if user.current_bot?

    if !@voice.has_key? server
      @voice[server] = {}
    end

    if channel and !@voice[server].has_key? channel
      @voice[server][channel] = []
    end

    name = (user.username.gsub /[0-9]+$/, "").downcase

    @voice[server].each do |k,v|
      if v.include? user and k != channel
        v.delete user
        if v.size >= 1
          # notify users, this isn't just an initial load.
          send_message bot, server, k, user, "#{name} left"
        end
      end
    end

    if channel and !@voice[server][channel].include? user
      @voice[server][channel] << user
      total_server = @voice[server].map { |l| l.size }.reduce(0, :+)
      if total_server == 1 and @voice[server][channel].size == 1
        send_message bot, server, channel, user, "You look nice today, #{name}"
      elsif @voice[server][channel].length >= 2
        send_message bot, server, channel, user, "#{name} joined"
      end
    end
  end
end
