require 'discordrb'
require 'json'

class Discordrb::Bot
  def get_base_directory
    File.expand_path(".")
  end

  # Retrieves the json-encoded configuration file from configs/
  # for the passed module in a consistent manner. If it's unavailable,
  # returns an empty dict.
  def get_config_for_module(module_filename)
    name = File.basename(module_filename, ".rb")
    file = "#{File.join(get_base_directory, "config", name)}.json"

    if File.exists? file
      JSON.load File.open file
    else
      {}
    end
  end
end
