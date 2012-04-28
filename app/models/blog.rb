class Blog < ActiveRecord::Base
  require 'open-uri'
  #validates_presence_of :blogger_name
  validates_presence_of :blog_url
  validates_format_of :blog_url, :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix
  validates_uniqueness_of :blog_url
  #Associations goes here
  has_many :posts
  

  #  Generic Method to read all blogs post
  #http://nokogiri.org/Nokogiri/XML/Node.html#method-i-xpath
  def read_blog_posts(blog)
    doc = Nokogiri::HTML(open("#{blog.blog_url}"))      
    xml_url = doc.css('head link[rel="alternate"]').first['href']
    xml_type = doc.css('head link[rel="alternate"]').first['type']
    xml_doc_url= xml_url.include?("http:") ? xml_url : "http:" + xml_url
    @xml_doc = Nokogiri::XML(open("#{xml_doc_url}"))      
    if !@xml_doc.nil?
      if xml_type == 'application/atom+xml'
        atom_parsing(blog,@xml_doc)
      end

      if xml_type == 'application/rss+xml'
        rss_parsing(blog,@xml_doc)
      end       
    end    
  end


  def atom_parsing(blog,xml_doc)
    xml_doc.css('entry').each do |node|
      blog_title = xml_doc.css('title').first.text        
      blog.blog_title = blog_title
      blog_author = xml_doc.css('author name').first.nil?  ? '' : xml_doc.css('author name').first.text
      blog.blog_author =  blog_author.blank? ? blog_title : blog_author
      blog.save!
      post = Post.new
      title = node.css('title').text 
      post.title = title
      post.blog_id = blog.id          
      post.url = "#"
      if !title.blank?         
        post_url = node.css('link[rel="alternate"]')
        post.url = !post_url.blank? ? post_url[0]['href'] : node.css('link')[0]['href']
      end    
      content = ''
      content = node.css('content').text
      post.content = content.blank? ? node.css('description').text : content
      post.author = blog_title
      post_author = node.css('author name').text         
      post.author = !post_author.blank? ? post_author : blog_title                                 
      published_date = node.css('updated').text 
      post.post_date = Time.parse(published_date.gsub('T'," "))          
      post.save!
    end      
  end 
  
  
  def rss_parsing(blog,xml_doc)
    xml_doc.css('item').each do |node|
       blog_title = xml_doc.css('title').first.text
       blog.blog_title = blog_title
       blog_author = xml_doc.css('author name').first.nil?  ? '' : xml_doc.css('author name').first.text            
       post = Post.new
       title = node.css('title').text 
       post.title = title
       post.blog_id = blog.id
       post.url = "#"
       if !title.blank?
          post.url = node.css('link').text
       end
       content = ''
       node.elements.each do |e|
         if e.name == "encoded"
           content = e.text
         end
         if e.name == "creator"
           blog_author = e.text
         end         
       end  
       blog.blog_author =  blog_author != '' ? (blog_author == 'admin' ? blog_title : blog_author) : blog_title
       blog.save!  
       post.content = content.blank? ? node.css('description').text : content
       post.author = blog_title
       post.author = blog.blog_author
       published_date = node.css('pubDate').text
       post.post_date = published_date.to_date
       post.save!
    end    
  end 

end
