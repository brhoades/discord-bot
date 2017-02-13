require 'rest-client'


module OverwatchAPI
  #TODO: Cache

  def get_username(bot, user)
    user.gsub! /#/, '-'

    if user =~ /\-/
      short_user = user.gsub(/-[0-9]+/, "").downcase
      owalias = OverwatchAlias.where(long: user)
      if owalias.size == 0
        short = OverwatchAlias.where(short: short_user)

        if short.size > 0
          short_user = "#{short_user}#{short.size}"
        end
        OverwatchAlias.new(long: user, short: short_user).save!
      end

      return {
        short: short_user,
        long: user,
        message: "You can use the alias: #{short_user}."
      }
    else
      owalias = OverwatchAlias.where(short: user.downcase).first

      if not owalias
        return nil
      end

      return {
        long: owalias.long,
        short: owalias.short,
        message: ""
      }
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
