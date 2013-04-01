class BlogsController < ApplicationController
  before_filter :authenticate_admin!,:except => ['read_blogs']
  
  layout :set_layout
  
  # GET /blogs
  # GET /blogs.json
  def index
    @blogs = Blog.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @blogs }
    end
  end

  # GET /blogs/1
  # GET /blogs/1.json
  def show
    @blog = Blog.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @blog }
    end
  end

  # GET /blogs/new
  # GET /blogs/new.json
  def new
    @blog = Blog.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @blog }
    end
  end

  # GET /blogs/1/edit
  def edit
    @blog = Blog.find(params[:id])
  end

  # POST /blogs
  # POST /blogs.json
  def create
    @blog = Blog.new(params[:blog])  
    respond_to do |format|
      if @blog.save
        request = Request.find_by_blog_url(@blog.blog_url)
        request.destroy if request
        @blog.read_blog_posts(@blog)
        format.html { redirect_to @blog, :notice => 'Blog was successfully created.' }
        format.json { render :json => @blog, :status => :created, :location => @blog }
      else
        format.html { render :action => "new" }
        format.json { render :json => @blog.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /blogs/1
  # PUT /blogs/1.json
  def update
    @blog = Blog.find(params[:id])

    respond_to do |format|
      if @blog.update_attributes(params[:blog])
        format.html { redirect_to @blog, :notice => 'Blog was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @blog.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /blogs/1
  # DELETE /blogs/1.json
  def destroy
    @blog = Blog.find(params[:id])
    Post.delete_all(["id in (?)",@blog.posts.collect(&:id)])
    @blog.destroy
    respond_to do |format|
      format.html { redirect_to blogs_url }
      format.json { head :ok }
    end
  end
  
  def read_blogs
    @blogs = Blog.all
    @posts = Post.order("post_date DESC").page(params[:page])
  end
  
  private
  def set_layout
     params[:action] == "read_blogs" ? 'application' : 'blogs'
  end
  
end
