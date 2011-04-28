class User < ActiveRecord::Base
  
  set_table_name "gb_users"
  
  validates_presence_of :first_name , :email , :role
  
  acts_as_authentic do |c|
    c.login_field = "email"
  end
  
  def full_name
    self.first_name = "" if self.first_name.blank?
    self.last_name = "" if self.last_name.blank?
    self.first_name + " " + self.last_name
  end
  
  def deliver_password_reset_instructions!  
    reset_perishable_token!
    puts "#{self.perishable_token}"
    Notifier.deliver_password_reset_instructions(self.id)  
  end
  
  def super_admin?
    self.role == "super_admin"
  end
  
  def admin?
    self.role == "admin"
  end
  
  def self.user_roles
    @roles ||= (["super_admin" , "admin"] << (Rails.configuration.user_roles) ).flatten
  end
  
end