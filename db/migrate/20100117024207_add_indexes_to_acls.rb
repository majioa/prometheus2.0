# encoding: utf-8

class AddIndexesToAcls < ActiveRecord::Migration
  def up
    add_index :acls, :branch
    add_index :acls, :vendor
    add_index :acls, :package
    add_index :acls, :login
  end

  def down
    remove_index :acls, :branch
    remove_index :acls, :vendor
    remove_index :acls, :package
    remove_index :acls, :login
  end
end
