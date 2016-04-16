class Play < ActiveRecord::Base
  belongs_to :game, inverse_of: :plays
  
  validates :x, :y, numericality: { only_integer: true, greater_than_or_equal_to: 0,
                                    less_than_or_equal_to: 2 }
  validates :player, numericality: { only_integer: true, greater_than_or_equal_to: 1,
                                     less_than_or_equal_to: 2 }
end
