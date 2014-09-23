Spree::Core::Engine.routes.draw do
  # Add your extension routes here

  Spree::Core::Engine.add_routes do
    namespace :api do
      resources :checkouts, only: [:create], format: 'json'
    end
  end
end
