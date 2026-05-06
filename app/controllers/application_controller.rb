class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :set_current_user
  helper_method :current_user, :other_users

  private

  def set_current_user
    Current.user = User.find_by(id: session[:current_user_id]) || User.first
    session[:current_user_id] = Current.user&.id
  end

  def current_user
    Current.user
  end

  def other_users
    User.where.not(id: current_user.id).order(:name)
  end
end
