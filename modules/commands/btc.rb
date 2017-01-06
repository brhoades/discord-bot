require 'gruff'
require 'net/http'
require 'uri'
require 'json'
require 'tempfile'

require_relative '../../bot-feature.rb'

module Enumerable
    def sum
      self.inject(0){|accum, i| accum + i }
    end

    def mean
      self.sum/self.length.to_f
    end

    def sample_variance
      m = self.mean
      sum = self.inject(0){|accum, i| accum +(i-m)**2 }
      sum/(self.length - 1).to_f
    end

    def standard_deviation
      return Math.sqrt(self.sample_variance)
    end
end 

class BTCFeature < BotFeature
  def load(bot)
    config = bot.get_config_for_module(__FILE__)
    @config = {
    }

    bot.map_config(config, @config)

    @location_cache = {}
  end

  def register_handlers(bot, scheduler)
    bot.message(contains: /^\!(btc|bitcoin)/) do |event|
      parts = event.message.to_s.split(/\s+/)
      parts.delete_at 0
      if parts.size == 0
        output_value event
        next
      end
      if parts[0] == "help"
        output_help event
        next
      elsif parts[0] == "day"
        parts[0] = "daily"
      elsif parts[0] == "month"
        parts[0] = "monthly"
      elsif parts[0] != "daily" and parts[0] != "monthly" and parts[0] != "alltime"
        event.respond "Unknown timespan."
        output_help event
        next
      end

      type = parts[0]
      data = get_graph_data type
      file = Tempfile.new ['graph', '.png']
      file.close

      begin
        build_graph(get_title(type), type, file, data)
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

  def get_title(unit)
    case unit
      when "daily"
        "BTC Last Day"
      when "monthly"
        "BTC Last Month"
      when "alltime"
        "BTC All Time"
    end
  end


  # Build a graph and write it to the passed file
  def build_graph(title, unit, file, data)
    graph = Gruff::Line.new
    graph.title = title
    labels = {}
    values = []
    number = 10 - 1

    if unit == "monthly"
      number -= 2
    end

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
    graph.data "BTC ($)", values

    graph.write(file.path)
  end

  # Put dates into a unit-appropriate format
  def massage_dates(data, unit)
    format = ""

    if unit == "daily"
      format = "%H:%M"
    elsif unit == "monthly"
      format = "%m/%d/%y"
    elsif unit == "alltime"
      format = "%m/%y"
    end

    data.each do |v|
      v["time"] = DateTime.parse(v["time"]).strftime(format)
    end
  end

  def output_help(event)
    event.respond %{
BTC Help:
  !btc: Display current btc value with statistics.
  !btc day/daily: Show the BTC price graphed for the last day.
  !btc month/monthly: Show the BTC price graphed for the last month.
  !btc alltime: show the BTC price graphed since records start.\
}
  end

  def output_value(event)
    data = get_graph_data("daily").map { |v| v["average"] }
    price = data.last
    average = data.mean
    stddev = data.standard_deviation
    
    event.respond %{\
BTC: $#{price}
BTC daily avg/stddev: $#{average.round(2)} / $#{stddev.round(2)}
}
  end
end
