class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def current_user
    User.find_by(name: 'Billy.Zheng')
  end
end
