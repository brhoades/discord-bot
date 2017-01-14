require_relative '../bf1_api.rb'


describe BF1BasicAPI do
  before(:each) do
    example_response = File.join(File.expand_path(File.dirname(__FILE__)), "example_weapons_response.json")
    example_response_contents = IO.read(example_response)

    rest = double("RestClient")
    response = double(body: example_response_contents)

    allow(rest).to receive(:get).and_return(response)
  end


  describe "#get_data" do
  end
end
