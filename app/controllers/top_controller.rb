class TopController < ApplicationController
  def index
    @articles = Article.order(released_at: :desc)

    @articles = @articles.open_to_the_public unless current_member
  end

  def about
  end

end
