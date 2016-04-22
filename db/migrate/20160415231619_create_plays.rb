class CreatePlays < ActiveRecord::Migration
  def change
    create_table :plays do |t|
      t.references :game, index: true, foreign_key: true
      t.integer :number
      t.integer :x
      t.integer :y

      t.timestamps null: false
    end
  end
end
