class Admin::ArticlesController < Admin::Base


    def index
        @articles = Article.order(released_at: :desc).page(params[:page]).per(5)
    end

    def show
        @article = Article.find(params[:id])
    end

    def new
        @article = Article.new
        @article.manages.build
    end

    def edit
        @article = Article.find(params[:id])
        @article.youtube_url_edit
    end

    def create
        @article = Article.new(article_params)

        url = params[:article][:youtube_url]
        url_edit = params[:article][:youtube_url]
        url = url.last(11)
        @article.youtube_url = url
        @article.youtube_url_edit = url_edit
        if @article.save
            redirect_to [:admin, @article], notice: "ニュースを登録しました"
        else
            render "new"
        end
    end

    def update
        @article = Article.find(params[:id])
        @article.assign_attributes(article_params)
        if @article.save
            redirect_to [:admin, @article], notice: "ニュースを更新しました。"
        else
            render "edit"
        end
    end

    def destroy
        @article = Article.find(params[:id])
        @article.destroy
        redirect_to :admin_category_articles
    end

    def category

    end

    private def article_params
        params.required(:article).permit(
            :title,
            :body,
            :released_at,
            :no_expiration,
            :expired_at,
            :member_only,
            { :category_ids=> [] }
        )
        end
end
