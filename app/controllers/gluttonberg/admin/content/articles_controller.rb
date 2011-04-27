# encoding: utf-8

module Gluttonberg
  module Admin
    module Content    
      class ArticlesController < Gluttonberg::Admin::BaseController
        
        before_filter :find_blog
        before_filter :find_article, :only => [:show, :edit, :update, :delete, :destroy]
        
        def index
          @articles = Article.all(:conditions => {:blog_id => @blog.id})
        end
        
        
        def show
          @comment = Comment.new
        end
        
        def new
          @article = Article.new
          @authors = User.all
        end
        
        def create
          @article = Article.new(params[:gluttonberg_article])
          if @article.save
            redirect_to admin_blog_articles_path(@blog)
          else
            render :edit
          end
          
        end
        
        def edit
          @authors = User.all
          unless params[:version].blank?
            @version = params[:version]  
            @article.revert_to(@version)
          end
        end
        
        def update
          if @article.update_attributes(params[:gluttonberg_article])
            redirect_to admin_blog_articles_path(@blog)
          else
            render :edit
          end
        end
        
        def delete
          display_delete_confirmation(
            :title      => "Delete Article '#{@article.title}'?",
            :url        => admin_blog_article_path(@blog, @article),
            :return_url => admin_blog_articles_path(@blog), 
            :warning    => ""
          )
        end
        
        def destroy
          if @article.delete
            flash[:notice] = "Article deleted."
            redirect_to admin_blog_articles_path(@blog)
          else
            flash[:error] = "There was an error deleting the Article."
            redirect_to admin_blog_articles_path(@blog)
          end
        end
        
        protected
        
          def find_blog
            @blog = Blog.find(params[:blog_id])
          end
          
          def find_article
            @article = Article.find(params[:id])
          end
        
      end
    end
  end
end
