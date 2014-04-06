class EventsController < ApplicationController
  def index
    if !params[:search]
      @events = Event.paginate(page: params[:page])
    else
      @filtered = []

      Event.all.each do |e|
        next unless e.title =~ /#{params[:search][:title]}/i
        next unless params[:search][:dow].include? e.from.localtime.wday.to_s

        type_match = false

        e.types.each do |t|
          type_match = true if params[:search][:types].include? t.id.to_s
        end

        next unless type_match

        @filtered << e
      end

      @events = @filtered.paginate(page: params[:page])
    end
  end

  def show
    @event = Event.find(params[:id])

    respond_to do |format|
      format.html
      format.ics do
        require 'icalendar'
        reminder = params[:reminder] || 30

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
            trigger "-P0DT0H#{reminder}M0S"
          end
        end

        cal.publish
        @ics = cal.to_ical
      end
    end
  end

  def search
  end
end
