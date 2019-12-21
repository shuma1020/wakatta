class CommentsController < ApplicationController
  def create
    @article = Article.find(params[:article_id])
    @comment = @article.comments.new(comment_params)
    @comment.member_id = current_member.id
    if @comment.save!
      redirect_back(fallback_location: admin_root_path)
    else
      redirect_back(fallback_location: admin_root_path)
    end
  end

private
  def comment_params
    params.require(:comment).permit(:content, :member_id, :article_id)
  end
end
