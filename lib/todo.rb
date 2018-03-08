class Todo < ActiveRecord::Base
  validates :title, presence: true, length: {minimum: 3}
  validates :day, length: {is: 2}, allow_blank: true
  validates :month, length: {is: 2}, allow_blank: true
  validates :year, length: {is: 4}, allow_blank: true
end
