require_relative '../overwatch_api.rb'

include OverwatchAPI

describe OverwatchAPI do
  before(:each) do
    example_response = File.join(File.expand_path(File.dirname(__FILE__)), "example-response.json")
    example_response_contents = IO.read(example_response)

    rest = double("RestClient")
    response = double(body: example_response_contents)

    allow(rest).to receive(:get).and_return(response)
  end


  describe "#get_data" do
    describe "is given no user" do
      it "should return a hash with an error key" do
        expect(get_data("")).to have_key("error")
        expect("RestClient").to_not receive(:get)
        end
    end

    describe "is given a username with a symbol (excluding -)" do
      it "should return a hash with an error key" do
        ["!!", "@@", "##", "$$", "brodes#1", "user&2"].each do |name|
          expect(get_data(name)).to have_key("error")
          expect("RestClient").to_not receive(:get)
        end
      end
    end
  end

  describe "#deep_merge_hashes" do
    it "should return {} on {}, {}" do
      expect(deep_merge_hashes({}, {}).keys.size).to equal(0)
    end

    it "should merge a flat hash with no conflicts" do
      a = {"1": "1", "2": "2"}
      b = {"3": "3", "4": "4"}

      expect(deep_merge_hashes(a, b).keys.size).to equal(4)
    end

    it "should merge a flat hash with no conflicts where one side is empty" do
      a = {"1": "1", "2": "2"}
      b = {}

      expect(deep_merge_hashes(a, b).keys.size).to equal(2)
      expect(deep_merge_hashes(b, a).keys.size).to equal(2)
    end


    it "should merge a flat hash with conflicts by adding conflicts" do
      a = {"1": 1, "2": 2}
      b = {"1": 1, "2": 2}

      res = deep_merge_hashes(a, b)
      expect(res.keys.size).to equal(2)
      expect(res[:"1"]).to equal(2)
      expect(res[:"2"]).to equal(4)
    end

    it "should merge a 2-d hash by adding conflicts" do
      c = {cat: 1, dog: 2}
      a = {
        a: c,
        b: 1
      }
      b = {
        a: c,
        b: 2
      }

      res = deep_merge_hashes(a, b)
      expect(res.keys.size).to equal(2)
      expect(res[:a][:cat]).to equal(2)
      expect(res[:a][:dog]).to equal(4)
      expect(res[:b]).to equal(3)
    end
  end
end
