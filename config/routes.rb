Rails.application.routes.draw do
  get 'top/index'
  resources :members do
    get "search", on: :collection
  end
  root  "top#index"
  get "about", to: "top#about", as: "about"
  resource :session, only: [:create, :destroy]
end
