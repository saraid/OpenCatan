require 'digest/sha1'

class UserController < ApplicationController
  def create
    create_user and return if request.post?    
    render :action => 'index'
  end

  def login
    login_user and return if request.post?    
    render :action => 'index'
  end

  private
  def create_user
    user = User.new
    user.username = params[:username]
    user.password = Digest::SHA1.hexdigest(params[:password])
    user.save!
    render :text => params.to_json
  end

  def login_user
    user = User.find_by_username(params[:username])
    render :text => "Fail" and return true unless user.password == Digest::SHA1.hexdigest(params[:password])
    session[:user] = user.username
    render :text => session[:user]
  end
end
