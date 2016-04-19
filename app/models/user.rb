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
    if self != game.player1
      joined_games << game
    else
      raise InvalidUserError, "User cannot join game user created"
    end
  end
  
  # Resign from a pending game.
  def resign_from_game(game)
    game.resign self
  end
  
  # Get user game record (wins, losses, etc.).
  def game_record
    record = {
      wins: 0,
      losses: 0,
      draws: 0,
      pending_games: 0,
      games_created: created_games.size,
      games_joined: joined_games.size,
      games_played: created_games.size + joined_games.size
    }
    created_games.each do |game|
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
    end
    joined_games.each do |game|
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
    end
    return record
  end
end
