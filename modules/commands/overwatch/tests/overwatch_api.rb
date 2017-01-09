require 'rspec'
require_relative '../overwatch_api.rb'

include OverwatchAPI

describe OverwatchAPI do
  describe "#get_data" do

    describe "is given no user" do
      it "should return a hash with an error key" do
        expect(get_data("")).to have_key("error")
        end
    end

    describe "is given a username with a symbol (excluding -)" do
      it "should return a hash with an error key" do
        ["!!", "@@", "##", "$$", "brodes#1", "user&2"].each do |name|
          expect(get_data(name)).to have_key("error")
        end
      end
    end
  end
end
