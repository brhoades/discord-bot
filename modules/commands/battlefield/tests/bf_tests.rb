require_relative '../basic_stats.rb'
require_relative '../detailed_stats.rb'

describe BF1DetailedStats do
  include BF1DetailedStats
  before(:example) do
    example_response = File.join(File.expand_path(File.dirname(__FILE__)), "example_weapons_response.json")
    example_response_contents = IO.read(example_response)

    @mock = stub_request(:any, /battlefieldtracker/).to_return(
      body: example_response_contents
    )
  end

  describe "#get_detailed_statistics" do
    it "should call get_data which should call RestClient#get" do
      get_detailed_statistics("somename")

      assert_requested @mock
    end

    it "should return an error with an empty name" do
      result = get_detailed_statistics("")

      expect(result).to be_a Hash
      expect(result).to have_key("error")
      assert_not_requested @mock
    end

    it "should return a hash with a successful key" do
      result = get_detailed_statistics("somename")

      expect(result).to be_a Hash
      expect(result).to_not have_key("error")
      expect(result).to have_key("successful")
    end
  end
end

describe BF1BasicStats do
  include BF1BasicStats

  before(:example) do
    example_response = File.join(File.expand_path(File.dirname(__FILE__)), "example_basic_response.json")
    example_response_contents = IO.read(example_response)

    @mock = stub_request(:any, /battlefieldtracker/).to_return(
      body: example_response_contents
    )
  end

  describe "#get_basic_statistics" do
    it "should call get_data which should call RestClient#get" do
      get_basic_statistics("somename")

      assert_requested @mock
    end

    it "should return an error with an empty name" do
      result = get_basic_statistics("")

      expect(result).to be_a Hash
      expect(result).to have_key("error")
      assert_not_requested @mock
    end

    it "should return a hash with a successful key" do
      result = get_basic_statistics("somename")

      expect(result).to be_a Hash
      expect(result).to_not have_key("error")
      expect(result).to have_key("successful")
    end
  end

  describe "#pretty_basic_statistics" do
    it "should return a string" do
      expect(pretty_basic_statistics("somename")).to be_a String
    end

    it "should not contain nil or NaN" do
      expect(pretty_basic_statistics("somename")).to_not match(/NaN|nil/)
    end
  end
end
