class Game < ActiveRecord::Base
  # Game statuses
  PENDING = 0
  P1_WON = 1
  P2_WON = 2
  DRAW = 3
  ABANDONED = 4
  
  has_many :plays, inverse_of: :game
  belongs_to :player1, class_name: "User", foreign_key: "player1_id",
                       inverse_of: :created_games
  belongs_to :player2, class_name: "User", foreign_key: "player2_id",
                       inverse_of: :joined_games
  
  validates :status, numericality: { only_integer: true, greater_than_or_equal_to: 0,
                                     less_than_or_equal_to: 4 }
end
