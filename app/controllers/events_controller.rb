class EventsController < ApplicationController
  def index
    @events = Event.paginate(page: params[:page])
  end

  def show
    @event = Event.find(params[:id])
  end
end
