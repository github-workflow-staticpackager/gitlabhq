# frozen_string_literal: true

resources(:organizations, only: [:show, :index, :new], param: :organization_path, module: :organizations) do
  collection do
    post :preview_markdown
  end

  member do
    get :activity
    get :groups_and_projects
    get :users

    resource :settings, only: [], as: :settings_organization do
      get :general
    end

    resource :groups, only: [:new], as: :groups_organization
  end
end
