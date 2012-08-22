Hybrid::Application.routes.draw do

  resources :concepts do
    collection do
      post :open_folder
      post :search_folder
      post :info_external
    end
    member do
      post :info
    end
  end

  resources :concept_property_concepts

  resources :dictionaries do
    member do
      get :export_to_csv
      post :remove_concepts_and_relations
    end
  end

  resources :file_types

  resources :mappings do
    collection do
      post :update_multiple
      get :search_available
    end
    member do
      post :expanded
      post :info
    end
  end

  resources :queries do
    member do
      post :total_records_count
      post :data_files
      post :load_file_type
      post :reorder
      post :edit_name
      post :save_name
      post :undo
      post :redo
      post :copy
    end
  end

  resources :query_concepts do
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
  resources :query_users

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
      post :table_columns
      get :download_file
      post :remove_all_mappings
    end
  end

  resources :source_joins

  resources :source_file_types

  resources :source_rules

  devise_for :users, controllers: { registrations: 'contour/registrations', sessions: 'contour/sessions', passwords: 'contour/passwords', confirmations: 'contour/confirmations', unlocks: 'contour/unlocks' }, path_names: { sign_up: 'register', sign_in: 'login' }

  resources :users do
    collection do
      post :activate
    end
    member do
      post :update_settings
    end
  end

  match "/about" => "sites#about", as: :about
  match "/settings" => "users#settings", as: :settings

  root to: "queries#show"

  # See how all your routes lay out with "rake routes"
end
