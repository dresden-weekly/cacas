class Project < ActiveRecord::Base
   self.primary_key = "id"
   belongs_to :user

   before_create do |rec|
     rec.id = UUID.new.generate
   end
end
