module VoiceState
  # Called on a voice event. If it's not us, we internally
  # update our voice session tracking.
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
      if @config[:custom_greetings].has_key? name
        greetings = @config[:custom_greetings][name]

        # Seed by most recent hour
        rng = Random.new((Time.now.to_i / 60*60).ceil)

        send_message bot, server, channel, user, greetings[rng.rand(greetings.size)]
      else
        if @voice[server][channel].size == 1
          send_message bot, server, channel, user, "You look nice today, #{name}"
        elsif @voice[server][channel].length >= 2
          send_message bot, server, channel, user, "#{name} joined"
        end
      end
    end
  end

  # On first start, for all of our servers, walk through all voice states and update
  # users to their appropriate hashes.
  def get_voice_state(bot)
    bot.servers.each do |server_id, server|
      if not @voice.has_key? server
        @voice[server] = {}
      end

      server.voice_states.each do |user_id, voice_state|
        if not @voice[server].has_key? voice_state.voice_channel
          @voice[server][voice_state.voice_channel] = []
        end
        user = bot.users[user_id]

        next if user.current_bot?

        @voice[server][voice_state.voice_channel] << user
      end
    end
  end
end
