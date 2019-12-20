class Admin::CategoriesController < Admin::Base

  def index
    @categories = Category.all
  end

  def show
    @category = Category.find(params[:id])
    p "#####"
  p  @articles = @category.articles.all
  p "########"
  end

end