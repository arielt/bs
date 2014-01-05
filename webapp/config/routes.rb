Webapp::Application.routes.draw do
  resources  :active_sessions
  root :to => 'home#index'
end
