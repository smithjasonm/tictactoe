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

  after_initialize do |game|
    # Maintain state of game as 3x3 array containing in each space 1, 2, or nil
    @state = Array.new(3) { Array.new(3) }
    plays.each { |play| @state[play.x][play.y] = play.player }
  end
  
  # Make a play
  def play(player, x, y)
    unless status == PENDING
      raise IncompatibleGameStatusError, "Status must be PENDING; status is #{status}"
    end
    unless is_valid_play?(player, x, y)
      raise InvalidPlayError
    end
    
    plays.create! player: player, x: x, y: y
    @state[x][y] = player
    update_status
  end
  
  # Player 1 forfeits
  def player1_forfeits
    unless status == PENDING || status == P1_FORFEIT
      raise IncompatibleGameStatusError,
            "Status must be PENDING or P1_FORFEIT; status is #{status}"
    end
    
    self.status = P1_FORFEIT
  end
  
  # Player 2 forfeits
  def player2_forfeits
    unless status == PENDING || status == P2_FORFEIT
      raise IncompatibleGameStatusError,
            "Status must be PENDING or P2_FORFEIT; status is #{status}"
    end
    
    self.status = P2_FORFEIT
  end
  
  private
    
    # Determine whether a proposed play is valid
    # A play is valid if it is the given player's turn and the chosen space has not
    # not already been filled
    def is_valid_play?(player, x, y)
      player == plays.size % 2 + 1 && @state[x][y].nil?
    end
    
    # Update pending-game status based on plays made so far
    def update_status
      if plays.size > 2
        result = false
        3.times do |n|
          result = check_row(n)
          result = check_column(n) if result == false
          break unless result == false
        end
        result = check_diagonal_left_right if result == false
        result = check_diagonal_right_left if result == false
        if result != false
          self.status = result == 1 ? P1_WON : P2_WON
        elsif plays.size == 9
          self.status = DRAW
        end
      end 
    end
    
    # Check whether a given row contains a winning combination
    def check_row(row)
      x = @state[0][row]
      if !x.nil? && x == @state[1][row] && x == @state[2][row]
        return x
      else
        return false
      end
    end
    
    # Check whether a given column contains a winning combination
    def check_column(col)
      x = @state[col][0]
      if !x.nil? && x == @state[col][1] && x == @state[col][2]
        return x
      else
        return false
      end
    end
    
    # Check whether the diagonal beginning at the top left contains a winning combination
    def check_diagonal_left_right
      x = @state[0][0]
      if !x.nil? && x == @state[1][1] && x == @state[2][2]
        return x
      else
        return false
      end
    end
    
    # Check whether the diagonal beginning at the top right contains a winning combination
    def check_diagonal_right_left
      x = @state[2][0]
      if !x.nil? && x == @state[1][1] && x == @state[0][2]
        return x
      else
        return false
      end
    end
end
