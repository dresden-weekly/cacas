class User < ActiveRecord::Base
  self.primary_key = "id"
  has_many :projects

  before_create do |rec|
    rec.id = UUID.new.generate
  end
end
