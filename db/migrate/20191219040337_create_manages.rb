class CreateManages < ActiveRecord::Migration[6.0]
  def change
    create_table :manages do |t|
      t.references :member, null: false
      t.references :category, null: false
      t.timestamps
    end
  end
end
