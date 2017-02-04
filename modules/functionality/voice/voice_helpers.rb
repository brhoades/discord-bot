module VoiceHelpers
  def authorized_user(user)
    authed = false
    @config[:authorized_play_users].each do |name|
      if user.to_s =~ /^#{name}/i
        authed = true
        break
      end
    end

    authed
  end
end
