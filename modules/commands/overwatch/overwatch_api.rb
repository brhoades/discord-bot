require 'rest-client'


module OverwatchAPI
  #TODO: Cache

  def get_username(bot, user)
    user.gsub! /#/, '-'
    full_user = nil

    if user =~ /\-/
      full_user = bot.db[:overwatch].where(full_user: user).first
      short_user = user.gsub(/-[0-9]+/, "")

      if not full_user or (full_user.is_a?(Array) and full_user.length == 0)
        full_user_id = bot.db[:overwatch].insert(full_user: user, short_user: short_user)
      end

      return user
    else
      full_user = bot.db[:overwatch].where(short_user: user).first

      if not full_user or (full_user.is_a?(Array) and full_user.length == 0)
        return nil
      end
  
      if full_user.is_a?(Array)
        full_user.first[:full_user]
      else
        full_user[:full_user]
      end
    end
  end

  # Change things to ints if they're .0
  def convert_data_to_correct_types(data)
    def convert_to_appropriate_type(hash)
      hash.each do |k, v|
        if v.is_a?(Hash)
          convert_to_appropriate_type(v)
          next
        end

        if v.is_a?(Float) and v.to_i.to_f == v.to_f
          hash[k] = v.to_i
        end
      end

    end

    convert_to_appropriate_type(data)
  end

  # Gets a user's data and returns the JSON for it. If there's an error,
  # includes a "error" key.
  def get_data(user)
    url = "https://owapi.net/api/v3/u/#{user}/blob"

    if user =~ /[^A-Za-z0-9-]/
      return {"error" => "Error: username contains invalid symbols"}
    end


    begin
      res = RestClient.get(url)
    rescue RestClient::Exception => e
      return {"error" => "Error: #{e.to_s}\nWith URL: #{url}"}
    end

    ret = JSON.load res.body
    convert_data_to_correct_types ret
    ret
  end
end
