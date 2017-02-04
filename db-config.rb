require 'active_record'
require 'sqlite3'
require 'logger'

# Discover Models
Dir["#{File.expand_path(".")}/modules/**/models/*.rb"].each do |f|
  puts "Loaded module #{f}"
  require f
end


ActiveRecord::Base.logger = Logger.new('debug.log')
configuration = YAML::load(IO.read('database.yml'))
ActiveRecord::Base.establish_connection(configuration['development'])
