class EventsController < ApplicationController
  def index
    @events = Event.paginate(page: params[:page])
  end

  def show
    @event = Event.find(params[:id])

    respond_to do |format|
      format.html
      format.ics do
        require 'icalendar'

        cal = Icalendar::Calendar.new

        event = @event

        cal.event do
          dtstart DateTime.parse(event.from.localtime.to_s)
          dtend DateTime.parse(event.to.localtime.to_s)
          location event.location
          summary event.title
          description event.summary

          alarm do
            action "DISPLAY"
            summary "Alarm notification"
            trigger "-P0DT0H30M0S"
          end
        end

        cal.publish
        @ics = cal.to_ical
      end
    end
  end
end
