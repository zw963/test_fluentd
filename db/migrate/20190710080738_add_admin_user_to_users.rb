class AddAdminUserToUsers < ActiveRecord::Migration[5.2]
  def change
    User.create(name: 'Billy.Zheng')
  end
end
