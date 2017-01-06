require 'gruff'
require 'net/http'
require 'uri'
require 'json'
require 'tempfile'

require_relative '../../bot-feature.rb'

class BTCFeature < BotFeature
  def load(bot)
    config = bot.get_config_for_module(__FILE__)
    @config = {
    }

    bot.map_config(config, @config)

    @location_cache = {}
  end

  def register_handlers(bot, scheduler)
    bot.message(contains: /\!(btc|bitcoin)/) do |event|
      type = "daily"
      daily = get_graph_data type
      file = Tempfile.new ['graph', '.png']
      file.close

      begin
        build_graph("BTC in USD Value today", type, file, daily)
        file.open
        event.channel.send_file(file)
      ensure
        file.close
        file.unlink
      end
    end
  end

  private
  def get_graph_data(unit)
    url = case unit
      when "daily"
        "https://apiv2.bitcoinaverage.com/frontend/global/history/BTCUSD?period=daily"
      when "monthly"
        "https://apiv2.bitcoinaverage.com/frontend/global/history/BTCUSD?period=monthly"
      when "alltime"
        "https://apiv2.bitcoinaverage.com/frontend/global/history/BTCUSD?period=alltime"
    end
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.get(uri.request_uri)

    JSON.load response.body
  end


  # Build a graph and write it to the passed file
  def build_graph(title, unit, file, data)
    graph = Gruff::Line.new
    graph.title = title
    labels = {}
    values = []
    number = 10 - 1

    massage_dates data, unit

    data.each_with_index do |v, i|
      if i % (data.length.to_f/number).ceil == 0 and labels.size < number
        # skip the last label, add it manually
        labels[i] = v["time"]
      end
      values << v["average"]
    end

    labels[data.size-1] = data.last["time"]

    graph.labels = labels
    graph.data values

    all = [file.path, "/tmp/test.png"]
    all.each do |l|
      graph.write(l)
    end
  end

  # Put dates into a unit-appropriate format
  def massage_dates(data, unit)
    format = ""

    if unit == "daily"
      format = "%H:%M"
    end

    data.each do |v|
      v["time"] = DateTime.parse(v["time"]).strftime(format)
    end
  end
end
