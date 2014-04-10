class EventsController < ApplicationController
  def changelog
    @changes = Changelog.all.reverse
  end

  def ongoing
    @events = Event.where("\"from\" <= ?", DateTime.now)
                   .where("\"to\" >= ?", DateTime.now)
                   .paginate(page: params[:page])

    render 'index'
  end

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

    respond_to do |format|
      format.html
      format.ics do
        require 'icalendar'

        cal = Icalendar::Calendar.new

        Event.all.each do |e|
          cal.event do
            dtstart DateTime.parse(e.from.localtime.to_s)
            dtend DateTime.parse(e.to.localtime.to_s)
            location e.location
            summary e.title
            description e.summary
          end
        end

        cal.publish

        @ics = cal.to_ical
      end
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
          dtstart DateTime.parse(event.from.to_s)
          dtend DateTime.parse(event.to.to_s)
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
