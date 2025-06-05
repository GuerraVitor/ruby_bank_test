class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(username: params[:username])

    if user && user.password == params[:password]
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: "login feito com sucesso!"
    else
      flash.now[:alert] = "senha ou usuário inválidos."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "logout feito com sucesso!", status: :see_other
  end
end