class Notifier < ActionMailer::Base
  
  default :from => "#{Gluttonberg::Setting.get_setting("title")} <#{Gluttonberg::Setting.get_setting("from_email")}>"
  default_url_options[:host] = Rails.configuration.host_name 
  
  def password_reset_instructions(user_id)
    user = User.find(user_id)
    setup_email
    @subject += "Password Reset Instructions"
    @recipients = user.email  
    @body[:edit_password_reset_url] = edit_admin_password_reset_url(user.perishable_token)
  end
  
  def comment_notification(subscriber , article , comment)
    @subscriber = subscriber
    @article = article
    @comment = comment
    @website_title = Gluttonberg::Setting.get_setting("title")
    @article_url = blog_article_url(article.blog.slug, article.slug)
    @unsubscribe_url = unsubscribe_article_comments_url(@subscriber.reference_hash)
    
    mail(:to => @subscriber.author_email, :subject => "Re: [#{@website_title}] #{@article.title}")
  end
  
  protected
  
    def setup_email
      @from        = "#{Gluttonberg::Setting.get_setting("title")} <#{Gluttonberg::Setting.get_setting("from_email")}>"
      @subject     = "[#{Gluttonberg::Setting.get_setting("title")}] "
      @sent_on     = Time.now
      @content_type = "text/html"
    end
    
end