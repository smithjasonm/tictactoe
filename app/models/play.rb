class Play < ApplicationRecord
  belongs_to :game, inverse_of: :plays
  
  validates :x, :y, numericality: { only_integer: true, greater_than_or_equal_to: 0,
                                    less_than_or_equal_to: 2 }
  validates :number, numericality: { only_integer: true, greater_than_or_equal_to: 1,
                                     less_than_or_equal_to: 9 }
  validates :game, presence: true
  
  # Prevent plays from being destroyed.
  before_destroy { raise ReadOnlyRecord }
  
  # Prevent plays from being changed after creation.
  def readonly?
    !new_record?
  end
  
  # Return number of player who made this play. The first play is made by player 1.
  def player
    return number.odd? ? 1 : 2
  end
end
