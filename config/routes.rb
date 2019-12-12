Rails.application.routes.draw do
  get 'top/index'
  resources :posts
  root to: "posts#index"
  get "/about", to: "posts#about"
end
