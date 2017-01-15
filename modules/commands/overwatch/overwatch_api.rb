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

  # Recursively merge two passed hashes.
  # If keys contain specific substrings, they can be added or compared.
  def deep_merge_hashes(a, b)
    merged = {}

    (a.keys + b.keys).uniq.each do |key|
      if not a.has_key?(key)
        merged[key] = b[key]
        next
      elsif not b.has_key?(key)
        merged[key] = a[key]
        next
      end
      av = a[key]
      bv = b[key]

      # Undefined behavior when one side is a hash but the other isn't.
      if av.is_a? Hash and bv.is_a? Hash
        merged[key] = deep_merge_hashes(av, bv)
        next
      elsif av.is_a? Hash
        merged[key] = av
        next
      elsif b[key].is_a? Hash
        merged[key] = bv
        next
      end

      if av.is_a?(Numeric) and bv.is_a?(Numeric)
        if key.is_a?(String) and key =~ /most|max|best|accuracy/i
          # Greater
          if av >= bv
            merged[key] = av
          else
            merged[key] = bv
          end
        else
          # Sum
          merged[key] = av + bv
        end
      else
        # Choose one :\
        merged[key] = av
      end
    end

    merged
  end

  # Change things to ints if they're .0
  # Recursively walks through a passed hash.
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

    if user =~ /[^A-Za-z0-9-]/ or user =~ /^\s*$/
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
