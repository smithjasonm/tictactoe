class Game < ActiveRecord::Base
  # Game statuses
  PENDING = 0
  P1_WON = 1
  P2_WON = 2
  DRAW = 3
  P1_FORFEIT = 4
  P2_FORFEIT = 5
  
  has_many :plays, lambda { order "number ASC" }, inverse_of: :game,
                   dependent: :delete_all
  belongs_to :player1, class_name: "User", foreign_key: "player1_id",
                       inverse_of: :created_games
  belongs_to :player2, class_name: "User", foreign_key: "player2_id",
                       inverse_of: :joined_games
  
  validates :status, numericality: { only_integer: true, greater_than_or_equal_to: 0,
                                     less_than_or_equal_to: 5 }

  after_initialize do |game|
    # Initialize status if new game. (Status should be set only from within this class.)
    self.status = PENDING if new_record?
    
    # Maintain state of game as 3x3 array containing in each space 1, 2, or nil
    # (for plays by player 1, plays by player 2, and empty spaces respectively).
    # TODO: Fetch plays lazily
    @state = Array.new(3) { Array.new(3) }
    plays.each { |play| @state[play.x][play.y] = play.player }
  end
  
  # Return next valid play number, or -1 if game is not pending
  def next_play_number
    return -1 unless status == PENDING
    return plays.length + 1
  end
  
  # Determine whether a given position is valid.
  def position_valid?(x, y)
    [x, y].each do |a|
      return false unless a.is_a?(Integer) && a >= 0 && a <= 2
    end
    return true
  end
  
  # Determine whether given position is available.
  def position_available?(x, y)
    unless position_valid?(x, y)
      raise InvalidPlayPositionError
    end
    @state[x][y].nil?
  end
  
  def position_state(x, y)
    unless position_valid?(x, y)
      raise InvalidPlayPositionError
    end
    @state[x][y]
  end
  
  # Make a play. Saves play and self automatically. Returns the new play.
  def make_play(number, x, y)
    play = nil
    with_lock do
      unless status == PENDING
        raise IncompatibleGameStatusError, "Status must be PENDING; status is #{status}"
      end
      unless number == plays.length + 1
        raise InvalidPlayNumberError
      end
      unless position_available?(x, y)
        raise PositionUnavailableError
      end
      
      play = plays.create! number: number, x: x, y: y
      @state[x][y] = play.player
      update_status
      save!
    end
    return play
  end
  
  # Register forfeit by player 1.
  def player1_forfeits
    with_lock do
      unless status == PENDING || status == P1_FORFEIT
        raise IncompatibleGameStatusError,
              "Status must be PENDING or P1_FORFEIT; status is #{status}"
      end
      
      self.status = P1_FORFEIT
      save!
    end
    self
  end
  
  # Register forfeit by player 2.
  # TODO: Refactor
  def player2_forfeits
    with_lock do
      unless status == PENDING || status == P2_FORFEIT
        raise IncompatibleGameStatusError,
              "Status must be PENDING or P2_FORFEIT; status is #{status}"
      end
      
      self.status = P2_FORFEIT
      save!
    end
    self
  end
  
  # Register resignation (i.e., forfeit) by given user.
  def resign(user)
    if user == player1
      player1_forfeits
    elsif user == player2
      player2_forfeits
    else
      raise InvalidUserError, "User #{user.id} is not a player in this game"
    end
  end
  
  # Get player whose turn it is. Return nil if game is not pending.
  def whose_turn
    return nil unless status == PENDING
    return plays.size.even? ? player1 : player2
  end
  
  # Get winning player. Return nil if there is none.
  def winner
    case status
    when PENDING, DRAW
      return nil
    when P1_WON, P2_FORFEIT
      return player1
    when P2_WON, P1_FORFEIT
      return player2
    else
      raise "Status is invalid"
    end
  end
  
  # Determine whether game is pending
  def pending?
    status == PENDING
  end
  
  private
    
    # Update pending-game status based on plays made so far.
    def update_status
      if status == PENDING && plays.length > 2
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
        elsif plays.length == 9
          self.status = DRAW
        end
      end
      self
    end
    
    # Check whether a given row contains a winning combination;
    # if it does, return number of winning player; otherwise, return false.
    def check_row(row)
      x = @state[0][row]
      if !x.nil? && x == @state[1][row] && x == @state[2][row]
        return x
      else
        return false
      end
    end
    
    # Check whether a given column contains a winning combination;
    # if it does, return number of winning player; otherwise, return false.
    def check_column(col)
      x = @state[col][0]
      if !x.nil? && x == @state[col][1] && x == @state[col][2]
        return x
      else
        return false
      end
    end
    
    # Check whether diagonal beginning at top left contains a winning combination;
    # if it does, return number of winning player; otherwise, return false.
    def check_diagonal_left_right
      x = @state[0][0]
      if !x.nil? && x == @state[1][1] && x == @state[2][2]
        return x
      else
        return false
      end
    end
    
    # Check whether diagonal beginning at top right contains a winning combination;
    # if it does, return number of winning player; otherwise, return false.
    def check_diagonal_right_left
      x = @state[2][0]
      if !x.nil? && x == @state[1][1] && x == @state[0][2]
        return x
      else
        return false
      end
    end
end
