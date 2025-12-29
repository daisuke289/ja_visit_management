Rails.application.routes.draw do
  devise_for :users

  # ダッシュボード（ルート）
  root "dashboard#show"

  # 重要取引先
  resources :customers do
    member do
      post :sync_from_ja
    end
    resources :visit_plans, except: [ :index ]
    resources :visit_records, except: [ :index ]
    resources :actions, only: [ :create, :update, :destroy ] do
      member do
        patch :complete
        patch :cancel
      end
    end
    resources :family_members, except: [ :show ]
    resources :diagnoses
  end

  # 訪問計画一覧（全顧客横断）
  resources :visit_plans, only: [ :index ]

  # 訪問記録一覧（全顧客横断）
  resources :visit_records, only: [ :index ]

  # カレンダー
  get "calendar", to: "calendar#show", as: :calendar
  get "calendar/ical", to: "calendar#ical", as: :calendar_ical

  # JA全顧客検索API（Ajax用）
  resources :ja_customers, only: [ :index, :show ] do
    collection do
      get :search
    end
  end

  # 管理者機能
  namespace :admin do
    # ダッシュボード
    get "dashboard", to: "dashboard#show"

    # JA全顧客インポート
    resources :ja_customer_imports, only: [ :new, :create, :show ]

    # 重要取引先インポート
    resources :customer_imports, only: [ :new, :create, :show ]

    # 支店管理
    resources :branches

    # JA全顧客一覧
    resources :ja_customers, only: [ :index, :show ]
  end

  # システム管理者機能
  namespace :system do
    resources :users
    resources :branches
    resources :visit_types
  end

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check
end
