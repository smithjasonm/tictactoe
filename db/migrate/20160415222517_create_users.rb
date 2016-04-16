class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :handle
      t.string :email
      t.string :password_digest

      t.timestamps null: false
    end
    add_index :users, :handle, unique: true
    add_index :users, :email, unique: true
  end
end
