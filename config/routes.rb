Rails.application.routes.draw do
  get "sessions/new"
  get "sessions/create"
  get "sessions/destro"

 # Sets the root URL of the application to the login page (sessions#new)
  root 'sessions#new'

  # Defines a GET route for '/login' which maps to sessions#new
  # This is for displaying the login form.
  get 'login', to: 'sessions#new', as: :login

  # Defines a POST route for '/login' which maps to sessions#create
  # This is for submitting the login form.
  post 'login', to: 'sessions#create'

  # Defines a DELETE route for '/logout' which maps to sessions#destroy
  # This is for logging out. We use 'delete' as it's the standard HTTP verb for destroying a resource.
  delete 'logout', to: 'sessions#destroy', as: :logout

  # This route will point to the user's main dashboard/menu after login.
  # We will create this 'UsersController' and its 'dashboard' action in the next step.
  get 'dashboard', to: 'users#dashboard', as: :dashboard

  # Resourceful route for users if we later decide to have user creation/editing pages
  # For this intern test, we might not need all these, but 'resources' is a common Rails pattern.
  # For now, we'll keep it simple and just use users#dashboard.
  # resources :users, only: [:new, :create, :show] # Keep this commented for now to simplify
end
