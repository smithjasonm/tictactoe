class User < ActiveRecord::Base
  has_secure_password
  has_many :created_games, class_name: "Game", foreign_key: "player1_id",
                           inverse_of: :player1
  has_many :joined_games, class_name: "Game", foreign_key: "player2_id",
                           inverse_of: :player2

  minHandleLength = Rails.configuration.x.minimum_handle_length
  maxHandleLength = Rails.configuration.x.maximum_handle_length
  validHandleFormat = Rails.configuration.x.valid_handle_format
  maxEmailLength = Rails.configuration.x.maximum_email_address_length
  validEmailFormat = Rails.configuration.x.valid_email_format
  validates :handle, presence: true, length: { in: minHandleLength..maxHandleLength },
                     format: { with: validHandleFormat }
  validates :email, presence: true, length: { maximum: maxEmailLength },
                    format: { with: validEmailFormat }

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
end
