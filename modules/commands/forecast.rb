require 'forecast_io'
require 'geocoder'
require 'chronic_duration'

require 'bot-feature.rb'

class ForecastFeature < BotFeature
  def load(bot)
    config = bot.get_config_for_module(__FILE__)
    @config = {
      "forecast_io_key": "",
      "gmaps_api_key": ""
    }

    bot.map_config(config, @config)

    ForecastIO.configure do |configuration|
      configuration.api_key = @config[:forecast_io_key]
    end

    Geocoder.configure(api_key: @config[:gmaps_api_key])

    @location_cache = {}
  end

  def register_handlers(bot, scheduler)
    bot.add_help({
      command: ["forecast", "weather", "w"],
      short_help: %{!forecast/!weather/!w: forecast.io weather and forecast.},
      long_help: %{forecast.io weather and forecast for a particular region.
Usage:
  **!forecast** *<location>*: return the forecast for a provided location.
}
    })

    bot.message(contains: /\!(forecast|weather|w)(\s+|$)/) do |event|
      next if @config[:forecast_io_key] == "" or @config[:gmaps_api_key] == ""
      options = parse_args event.message.to_s

      if not options[:target] or options[:target] =~ /^\s*$/
        event.respond("!giphy no")
        next
      end

      query = options[:target]

      if @location_cache.has_key? query
        res = @location_cache[query]
      else
        res = Geocoder.search(query)
        @location_cache[query] = res
      end

      if res.length == 0
        event.respond("Unknown location")
        next
      elsif res.length > 1
        response = "Ambiguous location, matches:"
        res.each do |loc|
          response += "\n    #{loc.formatted_address}"
        end

        event.respond(response)
        next
      end

      location = res[0]
      forecast = ForecastIO.forecast(location.latitude, location.longitude)

      current = forecast["currently"]
      minute = forecast["minutely"]
      hour = forecast["hourly"]
      day = forecast["daily"]["data"][0]

      response = %{Forecast for #{location.formatted_address}:
__Temp__: #{current["temperature"]}F\
#{" (feels like #{current["apparentTemperature"]}F)." if current["temperature"] != current["apparentTemperature"]} \
__Low__: #{day["temperatureMin"]}F \
| __High__: #{day["temperatureMax"]}F \
| __Humidity__: #{current["humidity"]*100}% \
| __Wind__: #{current["windSpeed"]} mph

Currently #{minute&.dig("summary")&.downcase&.gsub(/\./, '')} with #{hour&.dig("summary")&.downcase}
#{forecast&.dig("daily", "summary")}\n}


      if forecast.has_key?("alerts") and forecast["alerts"].length
        forecast["alerts"].each do |alert|
          delta = alert["expires"].to_i - alert["time"].to_i
          from_now = ChronicDuration.output(delta, :format => :long)
          response += "**#{alert["title"]} expires in #{from_now}.**\n"
        end
      end

      event.respond(response)
    end
  end
end
