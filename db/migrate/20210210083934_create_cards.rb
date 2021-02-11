class CreateCards < ActiveRecord::Migration[6.0]
  def change
    create_table :cards do |t|
      t.string :pin, null: false
      t.string :name, null: false
      t.string :dr, null: false
      t.string :box, null: false

      t.timestamps
    end
  end
end
