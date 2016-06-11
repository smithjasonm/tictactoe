# Represents a user of the application.
class User < ApplicationRecord
  has_secure_password
  has_many :created_games, class_name: "Game", foreign_key: "player1_id",
                           inverse_of: :player1
  has_many :joined_games, class_name: "Game", foreign_key: "player2_id",
                           inverse_of: :player2

  minHandleLength = Rails.configuration.x.minimum_handle_length
  maxHandleLength = Rails.configuration.x.maximum_handle_length
  maxEmailLength  = Rails.configuration.x.maximum_email_address_length
  
  validates :handle,
      presence: true,
        length: { in: minHandleLength..maxHandleLength },
    uniqueness: { case_sensitive: false }
  
  validates :handle, format: {    with: /\A[a-z0-9]/i,
                               message: "must begin with a letter or number" }
  
  validates :handle,
    format: { without: /\W/,
              message: "can contain only letters, numbers, and underscores" }
  
  validates :email,
        presence: true,
          length: { maximum: maxEmailLength },
          format: { with: /.+@.+\..+/ },
      uniqueness: { case_sensitive: false }
  
  # Trim whitespace from relevant user input before validation
  before_validation :trim_whitespace

  # Create a new game.
  def create_game
    created_games.create!
  end
  
  # Join an existing game.
  def join_game(game)
    raise JoiningUserCreatedGameError if self == game.player1
    raise GameAlreadyJoinedError unless game.player2.nil? || self == game.player2
    
    joined_games << game
  end
  
  # Resign from a pending game.
  def resign_from_game(game)
    game.resign self
  end
  
  # Get user game record (wins, losses, etc.). If player is specified, get game
  # record against player.
  def game_record(player = nil)
    record = {
      wins: 0,
      losses: 0,
      draws: 0,
      pending_games: 0,
      games_created: 0,
      games_joined: 0,
      games_played: 0
    }
    tally_created_games record, player
    tally_joined_games record, player
    record[:games_played] = record[:games_created] + record[:games_joined]
    return record
  end
  
  # Get all games in which user is a participant, sorted in descending order
  # by time last updated.
  def all_games
    (created_games + joined_games).sort_by! { |game| game.updated_at }.reverse!
  end
  
  # Get user's ongoing games, sorted in descending order by time last updated.
  def ongoing_games
    all_games.select { |game| game.ongoing? }
  end
  
  # Get user's completed games, sorted in descending order by time last updated and
  # optionally limited to a given number of games.
  def completed_games(limit = nil)
    result = all_games.select { |game| game.completed? }
    result = result.take(limit) if limit
    result
  end
  
  # Get user's waiting game, or return nil if absent.
  def waiting_game
    created_games.find { |game| game.waiting? }
  end
  
  # Determine whether user is a player in the given game.
  def is_player_in?(game)
    [game.player1_id, game.player2_id].include? id
  end
  
  private
    
    # Account for created games in record
    def tally_created_games(record, player)
      created_games.each do |game|
        if player.nil? || game.player2_id == player.id
          case game.status
          when Game::P1_WON, Game::P2_FORFEIT
            record[:wins] += 1
          when Game::P2_WON, Game::P1_FORFEIT
            record[:losses] += 1
          when Game::DRAW
            record[:draws] += 1
          when Game::PENDING
            record[:pending_games] += 1
          end
          record[:games_created] += 1
        end
      end
    end
    
    # Account for joined games in record
    def tally_joined_games(record, player)
      joined_games.each do |game|
        if player.nil? || game.player1_id == player.id
          case game.status
          when Game::P2_WON, Game::P1_FORFEIT
            record[:wins] += 1
          when Game::P1_WON, Game::P2_FORFEIT
            record[:losses] += 1
          when Game::DRAW
            record[:draws] += 1
          when Game::PENDING
            record[:pending_games] += 1
          end
          record[:games_joined] += 1
        end
      end
    end
    
    # Trim whitespace from relevant user input
    def trim_whitespace
      self.handle = handle.try(:strip)
      self.email = email.try(:strip)
    end
end
