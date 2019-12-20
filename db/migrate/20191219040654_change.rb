class Change < ActiveRecord::Migration[6.0]
  def change
    rename_column :manages, :member_id, :article_id
  end
end
