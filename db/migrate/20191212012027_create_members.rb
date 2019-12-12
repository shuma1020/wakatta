class CreateMembers < ActiveRecord::Migration[6.0]
  def change
    create_table :members do |t|
      t.string :name, null: false
      t.string :full_name
      t.string :email
      t.date :birthday
      t.boolean :administration, null: false, default: false
      t.timestamps
    end
  end
end
