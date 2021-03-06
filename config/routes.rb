SleepPortal::Application.routes.draw do

  resources :concepts do
    collection do
      post :open_folder
      post :search_folder
    end
    member do
      post :info
    end
  end

  resources :dictionaries do
    member do
      post :clean
    end

    resources :domains
    resources :variables
  end

  resources :file_types

  resources :mappings do
    collection do
      get :automap_popup
    end
    member do
      post :info
    end
  end

  resources :searches do
    member do
      get :variables_popup
      get :open_folder
      get :search_folder
      get :autocomplete
      post :total_records_count
      post :data_files
      post :load_file_type
      post :reorder
      post :undo
      post :redo
      post :copy
    end
  end

  resources :criteria do
    collection do
      post :indent
      post :mark_selected
      post :select_all
      post :copy_selected
      post :trash_selected
      post :right_operator
    end
  end

  resources :query_sources

  resources :reports do
    member do
      post :get_csv
      post :get_table
      post :report_table
      post :edit_name
      post :save_name
      post :reorder
    end
  end

  resources :report_concepts

  resources :sources do
    member do
      post :auto_map
      get :table_columns
      get :download_file
      post :remove_all_mappings
      get :edit_table_name
      patch :update_table_name
    end

    resources :rules
  end

  resources :source_file_types

  devise_for :users, controllers: { registrations: 'contour/registrations', sessions: 'contour/sessions', passwords: 'contour/passwords', confirmations: 'contour/confirmations', unlocks: 'contour/unlocks' }, path_names: { sign_up: 'register', sign_in: 'login' }

  resources :users do
    collection do
      post :activate
    end
    member do
      post :update_settings
    end
  end

  get "/about" => "application#about", as: :about
  get "/settings" => "users#settings", as: :settings
  get "/matching" => "matching#matching", as: :matching
  post "/matching/add_variable" => "matching#add_variable", as: :add_variable
  post "/matching/add_criteria" => "matching#add_criteria", as: :add_criteria

  root to: "searches#show"

  # See how all your routes lay out with "rake routes"
end
