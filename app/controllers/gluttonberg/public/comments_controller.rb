module Gluttonberg
  module Public
    class CommentsController <  ActionController::Base
  
      def create
        @blog = Gluttonberg::Blog.first(:conditions => {:slug => params[:blog_id]})
        @article = Gluttonberg::Article.first(:conditions => {:slug => params[:article_id], :blog_id => @blog.id})
        @comment = @article.comments.new(params[:comment].merge(:blog_slug => params[:blog_id]))
        if @comment.save
          @subscription = CommentSubscription.find(:first , :conditions => {:article_id => @article.id , :author_email => @comment.writer_email })
          if @comment.subscribe_to_comments == "1" && @subscription.blank?
            @subscription = CommentSubscription.create( {:article_id => @article.id , :author_email => @comment.writer_email , :author_name => @comment.writer_name } )
          elsif (@comment.subscribe_to_comments.blank? || @comment.subscribe_to_comments == "0")  && !@subscription.blank?
            #unsubscribe
            @subscription.destroy 
          end
          redirect_to blog_article_path(@blog.slug, @article.slug)
        else
          redirect_to blog_article_path(@blog.slug, @article.slug)
        end
      end
  
    end
  end
end