class User < ActiveRecord::Base
end

class Channel < ActiveRecord::Base
end

class Server < ActiveRecord::Base
end

class Message < ActiveRecord::Base
  belongs_to :server
  belongs_to :channel
  belongs_to :user
end
