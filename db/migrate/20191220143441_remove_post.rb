class RemovePost < ActiveRecord::Migration[6.0]
  def change
    remove_column :comments, :post_id
    add_column :comments, :article_id, :integer
  end
end
