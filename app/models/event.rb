class Event < ActiveRecord::Base
  has_and_belongs_to_many :types

  def from_time
    from.localtime.strftime("%A %l:%M %p")
  end

  def to_time
    to.localtime.strftime("%A %l:%M %p")
  end
end
