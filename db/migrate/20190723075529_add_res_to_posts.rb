class AddResToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :res_correct, :boolean, default: false
  end
end
