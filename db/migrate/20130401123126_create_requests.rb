class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
      t.string :requestor_name
      t.string :blog_url

      t.timestamps
    end
  end
end
