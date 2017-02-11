# coding: utf-8
require 'gruff'
require 'net/http'
require 'uri'
require 'json'
require 'tempfile'
require 'text-table'


require 'bot-feature.rb'
require 'memoize.rb'
require_relative 'exchange.rb'

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
      "coinbase": {
         "name" => "Coinbase",
         "short" => ["cb", "coinbase"],
         "now" => {
           "url" => "https://api.coinbase.com/v2/prices/BTC-USD/spot",
           "location" => ["data", "amount"]
         },
      },
      "bitstamp": {
        "name" => "Bitstamp",
        "short" => ["bs", "bitstamp"],
        "now" => {
          "url" => "https://www.bitstamp.net/api/ticker/",
          "location" => ["last"]
        },
         "daily_change" => {
          "url" => "https://www.bitstamp.net/api/ticker/",
          "location" => [["last"], ["open"]],
          "calculate" => true
        }
      },
      "bitfinex": {
        "name" => "Bitfinex",
        "short" => ["bitfinex", "bf"],
        "now" => {
          "url" => "https://api.bitfinex.com/v2/ticker/tBTCUSD",
          "location" => [6]
        },
        "daily_change" => {
          "url" => "https://api.bitfinex.com/v2/ticker/tBTCUSD",
          "location" => [5],
          "calculate" => false
        }
      }
    }

    bot.map_config(config, @config)
    @exchanges = {}
    @config.map { |k, e| @exchanges[e["short"]] = Exchange.new(e) }
    @location_cache = {}
  end

  def register_handlers(bot, scheduler)
    bot.add_help({
      command: ["btc", "bitcoin"],
      short_help: %{!bitcoin/!btc: BTC value and graphs},
      long_help: %{BTC Statistics
Usage:
  !btc: Display current btc value with statistics.
  !btc day/daily: Show the BTC price graphed for the last day.
  !btc month/monthly: Show the BTC price graphed for the last month.
  !btc alltime: show the BTC price graphed since records start.\
}
    })
    bot.message(contains: /^\!(btc|bitcoin)(\s+|$)/) do |event|
      options = parse_args event.message.to_s

      if options[:args].has_key? "ex"
        event.respond output_value options[:args]["ex"]
        next
      else
        event.respond "```markdown\n#{output_value}```"
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
%{
  def get_graph_data(unit)
    url = case unit
      when "daily"
        "https://apiv2.bitcoinaverage.com/frontend/global/history/BTCUSD?period=daily"
      when "monthly"
        "https://apiv2.bitcoinaverage.com/frontend/global/history/BTCUSD?period=monthly"
      when "alltime"
        "https://apiv2.bitcoinaverage.com/frontend/global/history/BTCUSD?period=alltime"
      when "now"
        "https://apiv2.bitcoinaverage.com/frontend/constants/exchangerates/global"
    end
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.get(uri.request_uri)

    data = JSON.load response.body
    if unit != "now"
      data.reverse
    else
      data
    end
  end
}

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

  def output_value(ex=nil)
    if ex
      @exchanges.each do |k, exchange|
        if exchange.is_this_exchange? ex
          return "$#{exchange.get_price.round(2)}/฿ (#{exchange.name})"
        end
      end

      return "Unknown exchange #{ex}"
    end

    table = Text::Table.new
    table.head = ["Exchange", "$/฿", "% Daily Change"]
    table.rows = []
    @exchanges.map do |k, exchange|
      name = exchange.name
      price = exchange.get_price
      daily_change = nil

      if exchange.get_daily_change != "?"
        if exchange.get_daily_change >= 0
          sym = "+"
        else
          sym = ""
        end
        daily_change = "#{sym}#{(exchange.get_daily_change*100).round(4)}%"
      end

      table.rows << [name, price, daily_change]
    end

    table.to_s
  end

end

exchanges_now = {
      "coindesk": "https://api.coindesk.com/v1/bpi/currentprice.json"
}
