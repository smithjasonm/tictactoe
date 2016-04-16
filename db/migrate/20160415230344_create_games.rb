class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.integer :player1_id
      t.integer :player2_id
      t.integer :status

      t.timestamps null: false
    end
    add_index :games, :player1_id
    add_index :games, :player2_id
    add_index :games, :status
  end
end
