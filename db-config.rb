require 'active_record'
require 'sqlite3'
require 'logger'

# Discover Models
Dir["#{File.expand_path(".")}/modules/**/models/*.rb"].each do |f|
  puts "Loaded model #{f}"
  require f
end

ActiveRecord::Base.logger = Logger.new('db/logs/debug.log')
configuration = YAML::load(IO.read('database.yml'))
ActiveRecord::Base.establish_connection(configuration['development'])
