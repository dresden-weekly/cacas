class Project < ActiveRecord::Base
  belongs_to :employer, foreign_key: :client_id
end
