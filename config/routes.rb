Rails.application.routes.draw do
  get "sessions/new"
  get "sessions/create"
  get "sessions/destro"
  root 'sessions#new'

  get 'login', to: 'sessions#new', as: :login
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy', as: :logout

  get 'dashboard', to: 'users#dashboard', as: :dashboard

  get 'deposit', to: 'users#deposit_form', as: :deposit_form
  post 'deposit', to: 'users#process_deposit', as: :process_deposit

  get 'withdraw', to: 'users#withdraw_form', as: :withdraw_form
  post 'withdraw', to: 'users#process_withdraw', as: :process_withdraw

  get 'statement', to: 'users#statement', as: :statement

  get 'transfer', to: 'users#transfer_form', as: :transfer_form
  post 'transfer', to: 'users#process_transfer', as: :process_transfer

  get 'manager_visit_confirm', to: 'users#manager_visit_confirm', as: :manager_visit_confirm
  post 'request_manager_visit', to: 'users#request_manager_visit', as: :request_manager_visit
end
