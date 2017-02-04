class User < ActiveRecord::Base
end

class Channel < ActiveRecord::Base
end

class Server < ActiveRecord::Base
end

class Message < ActiveRecord::Base
  has_one :server
  has_one :channel
  has_one :user
end
