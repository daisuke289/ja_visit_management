#!/bin/bash
# JA重要取引先訪問管理システム - 初期セットアップスクリプト
# 使用方法: bash setup.sh

set -e

echo "=== JA Visit Management System Setup ==="
echo ""

# 1. プロジェクトディレクトリ確認
if [ ! -f "Gemfile" ]; then
    echo "エラー: Railsプロジェクトのルートディレクトリで実行してください"
    exit 1
fi

# 2. Gemfileにgemを追加
echo ">>> Gemfileを更新中..."

cat >> Gemfile << 'EOF'

# === JA Visit Management 追加gem ===

# 認証
gem 'devise'

# 権限管理
gem 'pundit'

# ページネーション
gem 'kaminari'

# バックグラウンドジョブ
gem 'good_job'

# Excel/CSV読み込み
gem 'roo'

# 日本語化
gem 'rails-i18n'
gem 'devise-i18n'

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end
EOF

# 3. bundle install
echo ">>> gem をインストール中..."
bundle install

# 4. RSpec設定
echo ">>> RSpec を設定中..."
rails generate rspec:install

# 5. Devise設定
echo ">>> Devise を設定中..."
rails generate devise:install
rails generate devise User

# 6. Pundit設定
echo ">>> Pundit を設定中..."
rails generate pundit:install

# 7. GoodJob設定
echo ">>> GoodJob を設定中..."
rails generate good_job:install

# 8. 基本モデル生成
echo ">>> 基本モデルを生成中..."

# 支店
rails generate model Branch \
  code:string:uniq \
  name:string

# ユーザーに追加フィールド
rails generate migration AddFieldsToUsers \
  name:string \
  role:integer \
  branch:references

# JA全顧客マスタ
rails generate model JaCustomer \
  customer_number:string:uniq \
  household_number:string \
  name:string \
  name_kana:string \
  birth_date:date \
  postal_code:string \
  address:string \
  phone:string \
  branch:references \
  deposit_balance:decimal \
  loan_balance:decimal \
  has_banking:boolean \
  has_mutual_aid:boolean \
  has_agriculture:boolean \
  has_funeral:boolean \
  has_gas:boolean \
  has_real_estate:boolean \
  last_synced_at:datetime

# 重要取引先
rails generate model Customer \
  customer_number:string:uniq \
  household_number:string \
  name:string \
  name_kana:string \
  postal_code:string \
  address:string \
  phone:string \
  branch:references \
  last_visit_date:date

# 訪問種別
rails generate model VisitType \
  name:string \
  display_order:integer \
  active:boolean

# 訪問計画
rails generate model VisitPlan \
  customer:references \
  user:references \
  visit_type:references \
  planned_date:date \
  planned_time:time \
  purpose:text \
  status:integer

# 訪問記録
rails generate model VisitRecord \
  customer:references \
  user:references \
  visit_type:references \
  visited_at:datetime \
  interviewee:string \
  content:text \
  customer_situation:text \
  visit_plan:references

# 次アクション
rails generate model Action \
  visit_record:references \
  customer:references \
  user:references \
  title:string \
  due_date:date \
  status:integer \
  completed_at:datetime

# 家族構成
rails generate model FamilyMember \
  customer:references \
  name:string \
  name_kana:string \
  birth_date:date \
  relationship:string \
  relationship_type:integer \
  generation:integer \
  is_living:boolean \
  is_cohabitant:boolean \
  address:string \
  phone:string \
  occupation:string \
  workplace:string \
  ja_customer_number:string \
  notes:text \
  parent_member:references \
  spouse_member:references \
  marriage_status:integer

# 財産診断
rails generate model Diagnosis \
  customer:references \
  user:references \
  diagnosed_on:date \
  title:string \
  notes:text

# 9. インデックス追加マイグレーション
echo ">>> インデックスを追加中..."

cat > db/migrate/$(date +%Y%m%d%H%M%S)_add_indexes.rb << 'MIGRATION'
class AddIndexes < ActiveRecord::Migration[8.0]
  def change
    # JaCustomer
    add_index :ja_customers, :household_number
    add_index :ja_customers, :name_kana

    # Customer
    add_index :customers, :household_number
    add_index :customers, :name_kana

    # FamilyMember
    add_index :family_members, :ja_customer_number

    # VisitPlan
    add_index :visit_plans, :planned_date
    add_index :visit_plans, :status

    # VisitRecord
    add_index :visit_records, :visited_at

    # Action
    add_index :actions, :due_date
    add_index :actions, :status
  end
end
MIGRATION

# 10. マイグレーション実行
echo ">>> データベースをセットアップ中..."
rails db:create
rails db:migrate

# 11. シードデータ
echo ">>> シードデータを作成中..."

cat > db/seeds.rb << 'SEEDS'
# 訪問種別マスタ
visit_types = [
  { name: '定期訪問', display_order: 1, active: true },
  { name: '依頼対応', display_order: 2, active: true },
  { name: '相続発生前相談', display_order: 3, active: true },
  { name: '相続発生後相談', display_order: 4, active: true },
  { name: '事業承継相談', display_order: 5, active: true },
  { name: '財産診断', display_order: 6, active: true },
  { name: '資産形成', display_order: 7, active: true },
  { name: 'その他', display_order: 8, active: true }
]

visit_types.each do |vt|
  VisitType.find_or_create_by!(name: vt[:name]) do |record|
    record.display_order = vt[:display_order]
    record.active = vt[:active]
  end
end

puts "訪問種別マスタを作成しました（#{VisitType.count}件）"

# 開発用サンプルデータ
if Rails.env.development?
  # システム管理者
  admin = User.find_or_create_by!(email: 'admin@example.com') do |u|
    u.password = 'password123'
    u.name = 'システム管理者'
    u.role = :system_admin
  end

  # サンプル支店
  branch = Branch.find_or_create_by!(code: '001') do |b|
    b.name = '本店'
  end

  # 本店管理者
  User.find_or_create_by!(email: 'honten@example.com') do |u|
    u.password = 'password123'
    u.name = '本店 太郎'
    u.role = :admin
    u.branch = branch
  end

  # 支店長
  User.find_or_create_by!(email: 'branch@example.com') do |u|
    u.password = 'password123'
    u.name = '支店 花子'
    u.role = :branch_manager
    u.branch = branch
  end

  puts "開発用ユーザーを作成しました"
  puts "  - admin@example.com / password123 (システム管理者)"
  puts "  - honten@example.com / password123 (本店管理者)"
  puts "  - branch@example.com / password123 (支店長)"
end
SEEDS

rails db:seed

echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "次のステップ:"
echo "  1. bin/dev でサーバー起動"
echo "  2. http://localhost:3000 にアクセス"
echo ""
