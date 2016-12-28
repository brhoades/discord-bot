require 'rest_client'
require 'chronic_duration'
require 'json'
require_relative '../../bot-feature.rb'


class BF1TrackerFeature < BotFeature
  def initialize
  end

  def register_handlers(bot, scheduler)
    bot.message(contains: /^[!\/]bf1?/) do |event|
      message = event.message.to_s.split(/ /)
      message.delete_at 0
      event.respond pretty_basic_statistics(message.join " ")
    end
  end

  private

  def get_basic_statistics(name)
    res = RestClient.get(
      "https://battlefieldtracker.com/bf1/api/Stats/BasicStats?platform=3&displayName=#{name}",
      headers={"TRN-Api-Key": "8d268253-de03-4b79-af4a-fe70b33d0b55"})

    return if not res or not res.code == 200

    JSON.load res.body
  end

  def pretty_basic_statistics(name)
    response = get_basic_statistics(name)
    return "Not Found" if not response
    result = response["result"]
    %{**#{response["profile"]["displayName"]}**
*K/D*: #{result["kills"]}/#{result["deaths"]}\t*W/L*: #{result["wins"]}/#{result["losses"]}\t\
*KPM*: #{result["kpm"]}
*Time played*: #{ChronicDuration.output(result["timePlayed"], :format => :long)}
#{result["rank"]["name"]} (#{result["rankProgress"]["current"]/result["rankProgress"]["total"]*100}%)}
  end
end
