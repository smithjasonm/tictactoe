Rails.application.routes.draw do
  root               'static_pages#home'
  
  get    'help'   => 'static_pages#help'
  get    'about'  => 'static_pages#about'
  
  get    'login'  => 'sessions#new'
  post   'login'  => 'sessions#create'
  delete 'logout' => 'sessions#destroy'

  resources :games do #, only: [:index, :show, :create, :update, :destroy] do
    resources :plays, only: [:index, :create] #, format: 'json'
  end
  
  resources :users do
    get 'search', on: :collection
  end
end
