module BF1
  module BasicStats

    # The experience required to get to a rank.
    def ranks(i)
      [0, 1000, 5000, 15000, 25000, 40000, 55000, 75000, 95000, 120000, 145000, 175000, 205000, 235000, 265000, 295000, 325000, 355000, 395000, 435000, 475000, 515000, 555000, 595000, 635000, 675000, 715000, 755000, 795000, 845000, 895000, 945000, 995000, 1045000, 1095000, 1145000, 1195000, 1245000, 1295000, 1345000, 1405000, 1465000, 1525000, 1585000, 1645000, 1705000, 1765000, 1825000, 1885000, 1945000, 2015000, 2085000, 2155000, 2225000, 2295000, 2365000, 2435000, 2505000, 2575000, 2645000, 2745000, 2845000, 2945000, 3045000, 3145000, 3245000, 3345000, 3445000, 3545000, 3645000, 3750000, 3870000, 4000000, 4140000, 4290000, 4450000, 4630000, 4830000, 5040000, 5260000, 5510000, 5780000, 6070000, 6390000, 6730000, 7110000, 7510000, 7960000, 8430000, 8960000, 9520000, 10130000, 10800000, 11530000, 12310000, 13170000, 14090000, 15100000, 16190000, 17380000, 20000000][i]
    end

    # Does a rest query to bf1tracker for basic stats for a provided username.
    def get_basic_statistics(name)
      if name =~ /^\s*$/
        return {"error" => "No username provided."}
      end

      get_data("https://battlefieldtracker.com/bf1/api/Stats/BasicStats?platform=3&displayName=#{name}")
    end

    # Given someone's rank and their progress towards the next rank, return their total experience
    def get_total_experience(rank, progress)
      if rank.to_i != 100
        ranks(rank.to_i) + progress.to_i
      else
        ranks(rank.to_i)
      end
    end

    # Grabs basic bf1tracker stats and returns a string summarizing them.
    def pretty_basic_statistics(name)
      response = get_basic_statistics(name)
      return response if not response.is_a? Hash or response.has_key? "error"

      result = response["result"]
      total = "#{get_total_experience(result["rank"]["number"], result["rankProgress"]["current"].round(0))}"
      kd = (result["kills"].to_f/result["deaths"].to_f).round(2)
      wl = (result["wins"].to_f/result["losses"].to_f).round(2)
      %{**#{response["profile"]["displayName"]}**
*K/D*: #{result["kills"]}/#{result["deaths"]} (#{kd})\t*W/L*: #{result["wins"]}/#{result["losses"]} (#{wl})\t\
*KPM*: #{result["kpm"]}
*Time played*: #{ChronicDuration.output(result["timePlayed"], :format => :long, :units => 3)}
#{result["rank"]["name"]} (#{(result["rankProgress"]["current"]/result["rankProgress"]["total"]*100).round(1)}% to next rank)\t\
#{total} XP (#{(total.to_f/ranks(100)*100).round(2)}% to rank 100)}
    end
  end
end
