class Game < ActiveRecord::Base
  # Game statuses
  PENDING = 0
  P1_WON = 1
  P2_WON = 2
  DRAW = 3
  P1_FORFEIT = 4
  P2_FORFEIT = 5
  
  has_many :plays, lambda { order "created_at ASC" }, inverse_of: :game,
                   dependent: :delete_all
  belongs_to :player1, class_name: "User", foreign_key: "player1_id",
                       inverse_of: :created_games
  belongs_to :player2, class_name: "User", foreign_key: "player2_id",
                       inverse_of: :joined_games
  
  validates :status, numericality: { only_integer: true, greater_than_or_equal_to: 0,
                                     less_than_or_equal_to: 5 }
  
  # Make a play
  def play(player, x, y)
    unless status === PENDING
      raise IncompatibleGameStatusError, "Status must be PENDING; status is #{status}"
    end
    unless is_valid_play?(player, x, y)
      raise InvalidPlayError
    end
    
    plays.create! player: player, x: x, y: y
    update_status
  end
  
  # Player 1 forfeits
  def player1_forfeits
    unless status === PENDING || status === P1_FORFEIT
      raise IncompatibleGameStatusError,
            "Status must be PENDING or P1_FORFEIT; status is #{status}"
    end
    
    self.status = P1_FORFEIT
  end
  
  # Player 2 forfeits
  def player2_forfeits
    unless status === PENDING || status === P2_FORFEIT
      raise IncompatibleGameStatusError,
            "Status must be PENDING or P2_FORFEIT; status is #{status}"
    end
    
    self.status = P2_FORFEIT
  end
  
  private
    
    # Determine whether a proposed play is valid
    def is_valid_play?(player, x, y)
      true
    end
    
    # Update game status based on plays made so far
    def update_status
    end
end
