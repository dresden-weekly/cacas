class AddRedmineLoginToUsers < ActiveRecord::Migration
  def change
    add_column :users, :redmine_login, :string
    add_column :users, :redmine_mail, :string
  end
end
