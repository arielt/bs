Webapp::Application.routes.draw do
  resources  :active_sessions
  root :to => 'active_sessions#index'
end
