module HttpAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate
  end

  private

  def authenticate
    return true if Rails.env.test?
    
    authenticate_or_request_with_http_basic do |username, password|
      # Use environment variables for username and password
      username == ENV['HTTP_BASIC_AUTH_USERNAME'] && 
      password == ENV['HTTP_BASIC_AUTH_PASSWORD']
    end
  end
end
