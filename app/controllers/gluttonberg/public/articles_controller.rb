module Gluttonberg
  module Public
    class ArticlesController <   Gluttonberg::Public::BaseController
      
      def index
        @blog = Gluttonberg::Blog.published.first(:conditions => {:slug => params[:blog_id]}, :include => [:articles])
        raise ActiveRecord::RecordNotFound.new if @blog.blank?
        @articles = @blog.articles.published
        
         respond_to do |format|
           format.html
           format.rss { render :layout => false }
        end
      end
  
      def show
        @blog = Gluttonberg::Blog.published.first(:conditions => {:slug => params[:blog_id]})
        raise ActiveRecord::RecordNotFound.new if @blog.blank?
        @article = Gluttonberg::Article.published.first(:conditions => {:slug => params[:id], :blog_id => @blog.id})
        raise ActiveRecord::RecordNotFound.new if @article.blank?
        @comments = @article.comments.where(:approved => true)
        @comment = Comment.new(:subscribe_to_comments => true)
      end
      
      def tag
        @articles = Article.tagged_with(params[:tag]).includes(:blog).published 
        @tags = Gluttonberg::Article.published.tag_counts_on(:tag)   
      end
      
      def unsubscribe
        @subscription = CommentSubscription.find(:first , :conditions => {:reference_hash => params[:reference] })
        unless @subscription.blank?
          @subscription.destroy
          flash[:notice] = "You are successfully unsubscribe from comments of \"#{@subscription.article.title}\""
          redirect_to blog_article_url(@subscription.article.blog.slug, @subscription.article.slug)
        end
      end
  
    end
  end
end