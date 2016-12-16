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
  end

  def register_handlers(bot, scheduler)
    bot.message(contains: /\!forecast/) do |event|
      parts = event.message.to_s.split(/ /)
      parts.delete_at 0

      res = Geocoder.search(parts.join(' '))
      if res.length == 0
        event.respond("Unknown location")
        next
      elsif res.length > 1
        event.respond("Ambiguous location.")
        next
      end

      location = res[0]
      puts location
      
      forecast = ForecastIO.forecast(location.latitude, location.longitude)
      puts forecast["minutely"]["summary"]

      response = \
"""
Forecast for #{location.formatted_address}:

Currently #{forecast["minutely"]["summary"].downcase.gsub(/./, '')} with #{forecast["hourly"]["summary"].downcase}
#{forecast["daily"]["summary"]}
"""

      forecast["alerts"].each do |alert|
        delta = alert["expires"].to_i - alert["time"].to_i
        from_now = ChronicDuration.output(delta, :format => :long)
        response += "**#{alert["title"]} expires in #{from_now}.**"
      end

      event.respond(response)
    end
  end
end
