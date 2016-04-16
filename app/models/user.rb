class User < ActiveRecord::Base
  has_secure_password
  has_many :created_games, class_name: "Game", foreign_key: "player1_id",
                           inverse_of: :player1
  has_many :joined_games, class_name: "Game", foreign_key: "player2_id",
                           inverse_of: :player2

  minHandleLength = Rails.configuration.x.minimum_handle_length
  maxHandleLength = Rails.configuration.x.maximum_handle_length
  maxEmailLength = Rails.configuration.x.maximum_email_address_length
  validates :handle, presence: true, length: { in: minHandleLength..maxHandleLength }
  validates :email, presence: true, length: { maximum: maxEmailLength },
                    format: { with: /.+@.+\..+/i }
end
