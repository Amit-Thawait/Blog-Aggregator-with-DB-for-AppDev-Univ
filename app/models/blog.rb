class Blog < ActiveRecord::Base
  require 'open-uri'
  #validates_presence_of :blogger_name
  validates_presence_of :blog_url
  validates_format_of :blog_url, :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix
  validates_uniqueness_of :blog_url
  #Associations goes here
  has_many :posts
  
  #This method will read the posts of the blogs and stores it in DB. Currently we are showing the posts directly from the DB.
  def read_posts(blog)
    @doc = Nokogiri::HTML(open("#{blog.blog_url}"))
      if !@doc.nil?
        @doc.css('div.post').each do |node|
          @post = Post.new
          title_url = node.css('h3.post-title a')
          @post.blog_id = blog.id
          blog.blog_title = @doc.css('h1.title').text
          blog.save!
          @post.url = "#"
          @post.url = title_url[0]['href'] if !title_url.blank?       
          @post.title = node.css('h3.post-title').text          
          @post.content = node.css('div.post-body').inner_html.chomp
          @post.author = node.css('span.fn').text          
          published_date = node.css('abbr.published') 
          @post.post_date = Time.parse(published_date[0]['title'].gsub('T'," "))          
          @post.save!
        end         
      end
  end
  
  # #  Generic Method to read all blogs post
  # def read_blog_posts(blog)
    # doc = Nokogiri::HTML(open("#{blog.blog_url}"))      
    # xml_url = doc.css('head link[rel="alternate"]').first['href']
    # xml_type = doc.css('head link[rel="alternate"]').first['type']
    # xml_doc_url= xml_url.include?("http:") ? xml_url : "http:" + xml_url
    # @xml_doc = Nokogiri::XML(open("#{xml_doc_url}"))      
    # if !@xml_doc.nil?
        # @xml_doc.css('entry').each do |node|
          # blog_title = @xml_doc.css('title').first.text        
          # blog.blog_title = blog_title
          # blog_author = @xml_doc.css('author name').first.nil?  ? '' : @xml_doc.css('author name').first.text #@xml_doc.css('author name').first.text
          # blog.blog_author =  blog_author.blank? ? blog_title : blog_author
          # blog.save!
          # @post = Post.new
          # title = node.css('title').text 
          # @post.title = title
          # @post.blog_id = blog.id          
          # @post.url = "#"
          # if !title.blank?         
            # post_url = node.css('link[rel="alternate"]') #node.css('link').text
            # @post.url = !post_url.blank? ? post_url[0]['href'] : node.css('link')[0]['href']
          # end    
          # @post.content = node.css('content').text#node.content
          # @post.author = blog_title
          # post_author = node.css('author name').text         
          # @post.author = !post_author.blank? ? post_author : blog_title                                 
          # published_date = node.css('updated').text 
          # @post.post_date = Time.parse(published_date.gsub('T'," "))          
          # @post.save!
        # end         
      # end    
  # end


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

      post.content = node.css('content').text
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
       blog.blog_author =  blog_author.blank? ? blog_title : blog_author
       blog.save!
       post = Post.new
       title = node.css('title').text 
       post.title = title
       post.blog_id = blog.id
       post.url = "#"
       if !title.blank?
          post.url = node.css('link').text
       end
       node.elements.each do |e|
         if e.name == "encoded"
           post.content = e.text
         end
       end       
       post.author = blog_title
       post_author = node.css('author name').text
       post.author = !post_author.blank? ? post_author : blog_title 
       published_date = node.css('pubDate').text
       post.post_date = published_date.to_date
       post.save!
    end    
  end
    

  
  #This method is used to read posts from pat's blogs
  #We know that separate method for each blog is not a good idea. It's quite difficult to write a generic method since everyone is following different styles for their blogs.
  #Anyway we are trying to figure it out...
  def read_posts_one(blog)
     @doc = Nokogiri::HTML(open("#{blog.blog_url}"))
       if !@doc.nil?
         author_name = @doc.css('title').text
         @doc.css('article.post').each do |node|
           @post = Post.new
           title_url = node.css('h1 a')           
           @post.blog_id = blog.id
           blog.blog_title = "#{author_name}'s blogs"
           blog.save!
           append_url = "http://patshaughnessy.net"
           @post.url = append_url + title_url[0]['href']
           @post.title = node.css('h1').text    
           #content_data = node.css('section.content').inner_html.chomp
           #@post.content = content_data.css('p a').last.attr('href')   
           #links = "http://patshaughnessy.net/" + node.css('section.content').css('a').map{ |link| link['href']}.last           
           content_orig = node.css('section.content').inner_html.chomp
           @post.content = full_content(content_orig,append_url,full_string_content="")     
           @post.author = author_name
           @post.post_date = node.css('span.date').text.to_date
           @post.save!
         end         
       end
  end
  
  #This method is used to read posts from Alex's blogs
   def read_posts_two(blog)
     @doc = Nokogiri::HTML(open("#{blog.blog_url}"))
       if !@doc.nil?   
         author_name = @doc.css('div#header h1').text
         @doc.css('div.post').each do |node|
         @post = Post.new
         title_url = node.css('div.title a')
         @post.blog_id = blog.id
         blog.blog_title = "#{author_name}'s blogs"
         blog.save!
         @post.title = node.css('div.title').text
         @post.post_date = node.css('div.date').text.to_date
         @post.url = "http://www.alexrothenberg.com/" + title_url[0]['href']
         @post.content  = node.css('div.extract').inner_html.chomp         
         @post.author = author_name        
         @post.save!
         end         
       end
  end  

 private
  # This method is used to append the default pat's url to the link which it is missed
  def full_content(content,link,full_string_content="")
    c = content.partition('a href')
    full_string_content << c[0] << c[1]
    if !c[2].empty?
      if c[2].include?('http')
        full_string_content << full_content(c[2],link)
      else
        d = c[2].partition('/')
        g = d[2].partition('>')
        full_string_content << d[0].to_s << link+d[1].to_s + g[0] + " target='_blank'" + g[1] +g[2]
      end
    end
    full_string_content
  end  

end
