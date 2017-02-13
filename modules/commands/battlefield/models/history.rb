class BattlefieldHistory < ActiveRecord::Base
  TYPE = {
    'general' => 0,
    'medals' => 1,
    'kits' => 2,
    'vehicles' => 3,
    'weapons' => 4
  }
end
