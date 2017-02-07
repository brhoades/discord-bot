require 'discordrb'
require 'json'
require 'sequel'

class Discordrb::Bot
  attr_accessor :db, :features
  alias_method :old_message, :message

  # the base directory of our bot... used to get config which is in /config from bot.rb.
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
      bot = nil

      if File.exists? file
        options = {}
        JSON.load(File.open(file)).map { |k, v| options[k.to_sym] = v }
        bot = self.old_new(options)
      else
        puts "\"#{file}\" is required but does not exist." and exit
      end

      bot.load_features
      bot.setup_database

      bot
    end
  end

  # Loads all features and prints out messages for them.
  def load_features
    Dir["#{get_base_directory}/modules/**/*.rb"].each do |f|
      if f !~ /test/
        require f
      end
    end
    @features = []

    BotFeature.descendants.each do |feature_class|
      feature = feature_class.new
      @features << feature

      puts "Loaded Feature \"#{feature_class}\""
    end
  end

  # Gets our database, assuming it has been set up properly.
  def setup_database
    Sequel.extension :migration
    @db = Sequel.sqlite 'sqlite3.db'

    puts "Applying migrations."
    Sequel::Migrator.apply(@db, File.join(get_base_directory, "migrations"))
  end

  # Override message to simply wrap it and report back errors to the channel.
  def message(attributes = {}, &block)
    old_message(attributes) do |event|
      begin
        block.call event
      rescue Exception => e
        message = ""
        if attributes.has_key?(:caller)
          message = " in module #{attributes[:caller]}"
        end

        puts message
        puts e.backtrace.join("\n")
        paginate_response(%{Error#{message}: #{e.to_s}\n\n#{e.backtrace.join("\n")}}, 9).map do |m|
          event.respond("```#{m}```")
        end
      end
    end
  end

  def register_method(name, &block)
    self.class.send(:define_method, name, block)
  end

  def paginate_response(someresponse, takeoff=0)
    return [someresponse] if someresponse.length < (2000-takeoff)

    # Split it so our largest chunk is 1999 (-takeoff) chars
    # The last entry is blank so toss it.
    # Regex: \s\S matches all characters including newlines.
    someresponse.scan(/[\s\S]{,#{1999-takeoff}}/)[0...-1]
  end
end
