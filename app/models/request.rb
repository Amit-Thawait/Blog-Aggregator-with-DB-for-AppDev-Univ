class Request < ActiveRecord::Base

  validates :requestor_name, :blog_url, :presence => true
  validates :blog_url, :uniqueness => true
  before_save :check_for_uniqueness, :only => [:create,:update]

  def check_for_uniqueness
    blog_url = Blog.find_by_blog_url(blog_url)
    blog_url.blank? ? true : false
  end

end
