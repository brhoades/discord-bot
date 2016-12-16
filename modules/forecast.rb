require 'forecast_io'
require 'geocoder'
require 'chronic_duration'

require_relative '../bot-feature.rb'

#TODO: Put keys in config
class ForecastFeature < BotFeature
  def initialize
    ForecastIO.configure do |configuration|
      configuration.api_key = ENV['FORECAST_KEY']
    end

    Geocoder.configure(api_key: ENV['GMAPS_API_KEY'])
    @location_cache = {}
  end

  def register_handlers(bot, scheduler)
    bot.message(contains: /\!forecast/) do |event|
      parts = event.message.to_s.split(/ /)
      parts.delete_at 0
      query = parts.join(' ')
      res = nil

      if query =~ /^\s*$/
        event.respond("No.")
        next
      end

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

Currently #{minute["summary"].downcase.gsub(/\./, '')} with #{hour["summary"].downcase}
#{forecast["daily"]["summary"]}\n}


      forecast["alerts"].each do |alert|
        delta = alert["expires"].to_i - alert["time"].to_i
        from_now = ChronicDuration.output(delta, :format => :long)
        response += "**#{alert["title"]} expires in #{from_now}.**\n"
      end

      event.respond(response)
    end
  end
end
