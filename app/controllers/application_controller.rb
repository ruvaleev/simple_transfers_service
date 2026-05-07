class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  helper_method :current_user

  private

  def current_user
    Current.user
  end

  def set_current_user
    Current.user = User.find_by(id: session[:current_user_id]) || User.first
    session[:current_user_id] = Current.user&.id
  end
end
