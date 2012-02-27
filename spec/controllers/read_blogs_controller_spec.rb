describe ReadBlogsController do
  describe "Get Index" do
     it "assigns all blogs details to @blog_objects" do     
      get :index 
      assigns(:blogs).should_not be_nil
      assigns(:posts).should_not be_nil          
      response.should render_template(:index) 
     end
  end 
end