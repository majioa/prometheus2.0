# encoding: utf-8

class CreateGroups < ActiveRecord::Migration
  def up
    create_table :groups do |t|
      t.string :name
      t.string :branch
      t.string :vendor

      t.timestamps
    end
  end

  def down
    drop_table :groups
  end
end
