class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :check_syncing_status

  private

    def check_syncing_status
      unless params[:controller] == 'static_pages' && params[:action] == 'syncing'
        if File.exists?(File.join(Rails.root, 'tmp/syncing.lock'))
          render 'static_pages/syncing'
        end
      end
    end
end
