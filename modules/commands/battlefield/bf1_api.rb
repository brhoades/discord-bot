require 'rest_client'
require 'json'

module BF1BasicAPI

  private
  # checks to be ran on all events, returns false if event should be skipped
  def handler_check(event)
    if not @enabled
      event.respond "Missing API Key"
      false
    else
      true
    end
  end

  # Returns a JSON hash if a valid result was provided; otherwise returns a string.
  def get_rest_api(path)
    begin
      res = RestClient.get(path, headers=@header)
    rescue RestClient::BadRequest
      return "Unknown user"
    end

    return "Unknown error" if !res or res.code != 200

    JSON.load res.body
  end

  # Given someone's rank and their progress towards the next rank, return their total experience
  def get_total_experience(rank, progress)
    @ranks[rank.to_i] + progress.to_i
  end
end
