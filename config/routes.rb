Rails.application.routes.draw do
  namespace :admin do
    get 'top/index'
  end
  root "top#index"
  get "about" => "top#about", as: "about"
  get "bad_request" => "top#bad_request"
  get "forbidden" => "top#forbidden"
  get "internal_server_error" => "top#internal_server_error"

  1.upto(18) do |n|
    get "lesson/step#{n}(/:name)" => "lesson#step#{n}"
  end

  resources :members, only: [:index, :show] do
    get "search", on: :collection
    resources :entries, only: [:index]
  end

  resource :session, only: [:create, :destroy]
  resource :account, only: [:show, :edit, :update]
  resource :password, only: [:show, :edit, :update]

  resources :articles, only: [:index, :show]
  resources :entries do
    patch "like", "unlike", on: :member
    get "voted", on: :collection
  end
  namespace :admin do
    root "top#index"
    resources :members do
      get "search", on: :collection
    end
    resources :articles
    resources :categories do
      resources :articles, only: [:index,:show]
      get "search", on: :collection
    end
  end
end
