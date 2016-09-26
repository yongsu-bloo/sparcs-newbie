class CreateXes < ActiveRecord::Migration
  def change
    create_table :xes do |t|

      t.timestamps null: false
    end
  end
end
