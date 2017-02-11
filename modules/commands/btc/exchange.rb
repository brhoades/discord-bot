require 'rest_client'

require 'memoize.rb'

class Exchange
  #{
  #  "
  #}
  def initialize(config)
    @name = config["name"]
    @short_name = config["short"][0]

    @now = config["now"]
    @config = config
  end

  def name
    @name
  end

  def is_this_exchange?(key)
    @config["short"].include? key
  end

  def short
    @short_name
  end

  # Gets the price for this exchange. Returns errors in "error".
  def get_price
    data = get_rest_data(@now["url"])
    return data["error"] if data.is_a? Hash and data.has_key? "error"

    data.dig(*@now["location"])&.to_f
  end

  # Get our daily change %
  def get_daily_change
    return "?" if !@config.has_key? "daily_change"

    dc = @config["daily_change"]
    data = get_rest_data(dc["url"])

    if dc.dig("calculate")
      # first array dig over second
      (data.dig(*dc["location"][0]).to_f / data.dig(*dc["location"][1]).to_f) - 1
    else
      data.dig(*dc["location"])
    end
  end

  def get_rest_data(url)
    begin
      res = RestClient.get(url)
    rescue RestClient::Exception => e
      return {"error" => "Error: #{e.to_s}\nWith URL: #{url}"}
    end

    JSON.load res.body
  end

  def finalize
    memoize 3, :get_rest_data
  end
end
