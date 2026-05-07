class SessionsController < ApplicationController
  def switch
    user = User.find(params[:user_id])
    session[:current_user_id] = user.id
    redirect_back_or_to root_path, notice: "Switched to #{user.name}"
  end
end
