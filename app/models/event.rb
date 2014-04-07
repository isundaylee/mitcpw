class Event < ActiveRecord::Base
  has_and_belongs_to_many :types

  def from_time
    from.strftime("%A %l:%M %p")
  end

  def to_time
    to.strftime("%A %l:%M %p")
  end

  def google_calendar_link
    "http://www.google.com/calendar/render?" + ({action: "TEMPLATE", text: title, dates: "#{from.utc.strftime('%Y%m%dT%H%M%SZ')}/#{to.utc.strftime('%Y%m%dT%H%M%SZ')}", details: summary, location: location}.to_query)
  end

  def mobile_google_calendar_link
    "https://www.google.com/calendar/gp#~calendar:" + ({view: 'e', action: "TEMPLATE", text: title, dates: "#{from.utc.strftime('%Y%m%dT%H%M%SZ')}/#{to.utc.strftime('%Y%m%dT%H%M%SZ')}", details: summary, location: location}.to_query)
  end
end
