class AddYoutubeUrlEditToArticles < ActiveRecord::Migration[6.0]
  def change
    add_column :articles, :youtube_url_edit, :string
  end
end
