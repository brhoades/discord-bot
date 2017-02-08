require_relative '../bot-feature.rb'

describe BotFeature do
  before do
    @feature = BotFeature.new
  end

  describe "#parse_args" do
    it "should return with empty args with an empty string" do
      args = @feature.parse_args ""

      expect(args[:command]).to equal(nil)
      expect(args[:args]).to be_empty
      expect(args[:target]).to equal(nil)
    end

    it "should return with just a command when that's all that is provided" do
      args = @feature.parse_args "!command"

      expect(args[:command]).to eq("command")
      expect(args[:args]).to be_empty
      expect(args[:target]).to equal(nil)
    end

    it "should return with just a command and a target if that's specified" do
      args = @feature.parse_args "!command target"

      expect(args[:command]).to eq("command")
      expect(args[:args]).to be_empty
      expect(args[:target]).to eq("target")
    end

    it "should parse a sole argument into args with a nil value" do
      args = @feature.parse_args "!command -arg"

      expect(args[:command]).to eq("command")
      expect(args[:args]).to eq({"arg" => nil})
      expect(args[:target]).to equal(nil)
    end

    it "should parse a sole argument value pair into a sole argument with a target when has_target=true" do
      args = @feature.parse_args "!command -arg target"

      expect(args[:command]).to eq("command")
      expect(args[:args]).to eq({"arg" => nil})
      expect(args[:target]).to eq("target")
    end

    it "should parse a sole argument value pair properly with has_target=false" do
      args = @feature.parse_args "!command -arg value", false

      expect(args[:command]).to eq("command")
      expect(args[:args]).to eq({"arg" => "value"})
      expect(args[:target]).to equal(nil)
    end

    it "should parse a multiple argument value pair" do
      args = @feature.parse_args "!command -arg1 value1 -arg2 -arg3 value3", false

      expect(args[:command]).to eq("command")
      expect(args[:args]).to eq({
        "arg1" => "value1",
        "arg2" => nil,
        "arg3" => "value3"
      })
      expect(args[:target]).to equal(nil)
    end

    it "should parse a mixed argument value pairs / sole argument" do
      args = @feature.parse_args "!command -arg1 value1 -arg2 -arg3 value3 -arg4", false

      expect(args[:command]).to eq("command")
      expect(args[:args]).to eq({
        "arg1" => "value1",
        "arg2" => nil,
        "arg3" => "value3",
        "arg4" => nil
      })
      expect(args[:target]).to equal(nil)
    end

    it "should parse multiple sole arguments" do
      args = @feature.parse_args "!command -arg1 -arg2", false

      expect(args[:command]).to eq("command")
      expect(args[:args]).to eq({
        "arg1" => nil,
        "arg2" => nil
      })
      expect(args[:target]).to equal(nil)
    end

    it "should parse a mixed argument value pairs / sole arguments and a target" do
      args = @feature.parse_args "!command -arg1 value1 -arg2 -arg3 value3 -arg4 target"

      expect(args[:command]).to eq("command")
      expect(args[:args]).to eq({
        "arg1" => "value1",
        "arg2" => nil,
        "arg3" => "value3",
        "arg4" => nil
      })
      expect(args[:target]).to eq("target")
    end

  end
end
