Rails.application.routes.draw do
  get 'entries/index'
  get 'entries/show'
  get 'entries/new'
  get 'entries/edit'
  get 'passwords/edit'
  get 'accounts/show'
  get 'accounts/edit'
  get 'top/index'
  resources :members do
    get "search", on: :collection
    resources :entries, only: [:index]
  end
  root  "top#index"
  get "about", to: "top#about", as: "about"
  resource :session, only: [:create, :destroy]
  resource :account, only: [:show, :edit, :update]
  resource :password, only: [:show, :edit, :update]
  resources :articles
  resources :entries
end
