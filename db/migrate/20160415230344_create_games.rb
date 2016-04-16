class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.integer :player1
      t.integer :player2
      t.integer :status

      t.timestamps null: false
    end
    add_index :games, :player1
    add_index :games, :player2
    add_index :games, :status
  end
end
