class EventsController < ApplicationController
  def index
    @events = Event.paginate(page: params[:page])
  end

  def show
  end
end
