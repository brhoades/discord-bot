class BattlefieldHistory < ActiveRecord::Base
  TYPE_NAMES = [
    'general',
    'details',
    'weapons',
    'medals',
    'vehicles'
  ]
end
