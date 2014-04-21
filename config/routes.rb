require "resque"
require "resque/server"
require "resque/tasks"

CocoaDocs2::Application.routes.draw do
  
  root 'api#index'

  get 'api/webhook' => 'api#webhook'
  get 'api/error' => 'api#error'
  get 'api/reparse' => 'api#reparse'
  
  mount Resque::Server.new, :at => "/dashboard"

end
