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

  # Map our read config to our bot config. This allows us to avoid
  # values that shouldn't be there and also keep defaults.
  def map_config(read_config, bot_config)
    read_config.each do |k, v|
      bot_config[k.to_sym] = read_config[k] if bot_config.has_key? k.to_sym
    end
  end

  # Gross way to let us monkeypatch a class method.
  class << self
    alias_method :old_new, :new

    # Load all of our options from config.json. This then overrides the real .new
    # and calls the alias.
    def new
      file = File.join(File.dirname(__FILE__), "config.json")
      options = nil

      if File.exists? file
        options = {}
        JSON.load(File.open(file)).map { |k, v| options[k.to_sym] = v }
        self.old_new(options)
      else
        puts "\"#{file}\" is required but does not exist." and exit
      end
    end
  end
end
