class CreateTodos < ActiveRecord::Migration[5.1]
  def change
    create_table :todos do |t|
      t.string :title
      t.boolean :completed
      t.string :day
      t.string :month
      t.string :year
      t.text :description
    end
  end
end
