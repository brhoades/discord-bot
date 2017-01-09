require 'rest-client'


module OverwatchAPI
  #TODO: Cache

  # Gets a user's data and returns the JSON for it. If there's an error,
  # includes a "error" key.
  def get_data(user)
    url = "https://owapi.net/api/v3/u/#{user}/blob"

    if user =~ /[^A-Za-z0-9-]/
      return {"error" => "Error: username contains invalid symbols"}
    end


    begin
      res = RestClient.get(url)
    rescue RestClient::Exception => e
      return {"error" => "Error: #{e.to_s}\nWith URL: #{url}"}
    end

    JSON.load res.body
  end
end
