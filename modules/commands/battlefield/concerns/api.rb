require 'rest_client'
require 'json'

module BF1
  module API
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
    def get_data(path)
        begin
        res = RestClient.get(path, headers=@header)
        rescue RestClient::BadRequest
        return {"error" => "Unknown user"}
        end

        return {"error" => "Unknown error"} if !res or res.code != 200

        JSON.load res.body
    end
  end
end
