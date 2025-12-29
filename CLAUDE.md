# 重要取引先訪問管理システム (JA Visit Management)

## プロジェクト概要

農協（JA）における重要取引先への訪問活動を一元管理するシステム。
105支店 × 約15,000世帯の重要取引先に対する訪問計画・実績・次アクションを管理し、
相続相談・事業承継における次世代アプローチを支援する。

### 解決する課題

- Excel管理による情報散在・入力負荷
- 本店による支店活動状況の把握遅延
- 訪問計画・次アクションの可視化不足
- 相続発生時の資金流出リスク（次世代が遠方の場合）

### 主な機能

1. **重要取引先管理** - 顧客番号/世帯番号をキーにCSV連携
2. **訪問管理** - 計画→実績記録→次アクション→次訪問のサイクル
3. **家系図管理** - 複雑な親族関係（離婚・再婚含む）の可視化
4. **財産診断管理** - PDF/PPTアップロード、履歴管理
5. **ダッシュボード** - 本店用（全支店横断）・支店用（自支店）

---

## 技術スタック

| 区分 | 技術 | 備考 |
|------|------|------|
| フレームワーク | Ruby on Rails 8 | Hotwire (Turbo/Stimulus) |
| データベース | PostgreSQL | 開発・テスト用。本番はSQL Server予定 |
| 認証 | Devise | 独自認証。将来的にAD連携検討 |
| ファイルストレージ | Active Storage | 財産診断PDF/PPT保存 |
| バックグラウンドジョブ | GoodJob | CSVインポート等 |
| CSSフレームワーク | Tailwind CSS | |
| テスト | RSpec + FactoryBot | |

### 開発環境

- ローカル VS Code + Claude Code
- Ruby 3.3.x
- Node.js 20.x（Tailwind/ESBuild用）

---

## Claude Code 開発ルール

### コード調査・分析は Serena MCP 必須

Rubyコード（`.rb`ファイル）の調査・分析時は、**必ずSerena MCPツールを使用**すること。

**禁止事項:**
- `.rb`ファイル全文を`Read`ツールで読み込むこと
- `cat`や`head`コマンドでRubyファイルを表示すること

**必須ツール:**
| 目的 | 使用ツール |
|------|-----------|
| ファイル内シンボル一覧取得 | `get_symbols_overview` |
| シンボル検索（クラス/メソッド） | `find_symbol` |
| 参照元の検索 | `find_referencing_symbols` |
| パターン検索（コード内文字列） | `search_for_pattern` |

**正しい調査フロー:**
1. `get_symbols_overview` でファイルの構造を把握
2. `find_symbol` で必要なメソッド/クラスを特定（`include_body: true`で本体取得）
3. `find_referencing_symbols` で影響範囲を調査

**例外（Read可）:**
- 設定ファイル: `.yml`, `.json`, `Gemfile`, `Procfile`等
- ビューテンプレート: `.erb`, `.html`
- ドキュメント: `.md`

---

## データモデル

### ER図（主要エンティティ）

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Branch    │────<│    User     │     │ VisitType   │
│   (支店)    │     │ (ユーザー)  │     │ (訪問種別)  │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Customer   │────<│VisitRecord │>────│VisitPlan   │
│(重要取引先) │     │ (訪問記録)  │     │ (訪問計画)  │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │
       │                   │
       ▼                   ▼
┌─────────────┐     ┌─────────────┐
│FamilyMember │     │   Action    │
│ (家族構成)  │     │(次アクション)│
└─────────────┘     └─────────────┘
       │
       ├──────────────────────┐
       ▼                      ▼
┌─────────────┐        ┌─────────────┐
│  Diagnosis  │        │ JaCustomer  │
│ (財産診断)  │        │(JA全顧客)   │
└─────────────┘        └─────────────┘
                             ▲
                             │
                       CSVインポート
                       (36,000件)
```

### テーブル定義

#### ja_customers（JA全顧客マスタ）

JAの基幹システムから定期的にCSVインポートする全顧客データ（約36,000件）。
家族構成入力時の顧客番号検索に使用。

| カラム | 型 | 説明 |
|--------|------|------|
| id | bigint | PK |
| customer_number | string | 顧客番号（一意、検索キー） |
| household_number | string | 世帯番号 |
| name | string | 氏名 |
| name_kana | string | 氏名カナ |
| birth_date | date | 生年月日 |
| postal_code | string | 郵便番号 |
| address | string | 住所 |
| phone | string | 電話番号 |
| branch_id | bigint | FK（取引支店） |
| deposit_balance | decimal | 預金残高（任意） |
| loan_balance | decimal | 貸出残高（任意） |
| **事業別取引フラグ** | | |
| has_banking | boolean | 金融取引有無 |
| has_mutual_aid | boolean | 共済加入有無 |
| has_agriculture | boolean | 営農取引有無 |
| has_funeral | boolean | 葬祭互助会有無 |
| has_gas | boolean | ガス契約有無 |
| has_real_estate | boolean | 不動産取引有無 |
| last_synced_at | datetime | 最終同期日時 |
| created_at | datetime | |
| updated_at | datetime | |

**インデックス:**
- `customer_number` (UNIQUE)
- `household_number`
- `name_kana`（カナ検索用）
- `branch_id`

**備考:**
- 現状、金融・共済・営農等で顧客番号が統一されていないため、まずは金融の顧客番号をキーとする
- 事業別フラグは手動設定 or 別途名寄せ処理で更新
- 将来的に事業別詳細テーブル（共済種類、営農作物等）への拡張を想定

#### branches（支店）

| カラム | 型 | 説明 |
|--------|------|------|
| id | bigint | PK |
| code | string | 支店コード（一意） |
| name | string | 支店名 |
| created_at | datetime | |
| updated_at | datetime | |

#### users（ユーザー）

| カラム | 型 | 説明 |
|--------|------|------|
| id | bigint | PK |
| email | string | メールアドレス（ログインID） |
| encrypted_password | string | パスワード（Devise） |
| name | string | 氏名 |
| role | enum | admin（本店管理者）, branch_manager（支店長）, system_admin |
| branch_id | bigint | FK（支店長の場合） |
| created_at | datetime | |
| updated_at | datetime | |

#### customers（重要取引先）

| カラム | 型 | 説明 |
|--------|------|------|
| id | bigint | PK |
| customer_number | string | 顧客番号（JAシステム連携キー、一意） |
| household_number | string | 世帯番号（任意） |
| name | string | 世帯主氏名 |
| name_kana | string | 氏名カナ |
| postal_code | string | 郵便番号 |
| address | string | 住所 |
| phone | string | 電話番号 |
| branch_id | bigint | FK（担当支店） |
| last_visit_date | date | 最終訪問日（キャッシュ） |
| created_at | datetime | |
| updated_at | datetime | |

#### family_members（家族構成）

| カラム | 型 | 説明 |
|--------|------|------|
| id | bigint | PK |
| customer_id | bigint | FK（重要取引先） |
| name | string | 氏名 |
| name_kana | string | 氏名カナ |
| birth_date | date | 生年月日 |
| relationship | string | 続柄（世帯主から見た関係） |
| relationship_type | enum | spouse（配偶者）, child（子）, grandchild（孫）, parent（親）, sibling（兄弟姉妹）, nephew_niece（甥姪）, other |
| generation | integer | 世代（世帯主を0として、親=+1、子=-1） |
| is_living | boolean | 存命フラグ |
| is_cohabitant | boolean | 同居フラグ |
| address | string | 住所（別居の場合） |
| phone | string | 電話番号 |
| occupation | string | 職業 |
| workplace | string | 勤務先 |
| ja_customer_number | string | JAの顧客番号（ja_customersと紐付け） |
| notes | text | 備考（「後継者候補」「遠方在住」など） |
| parent_member_id | bigint | FK（親の家族メンバーID、家系図用） |
| spouse_member_id | bigint | FK（配偶者の家族メンバーID） |
| marriage_status | enum | married（婚姻中）, divorced（離婚）, widowed（死別） |
| created_at | datetime | |
| updated_at | datetime | |

#### visit_types（訪問種別マスタ）

| カラム | 型 | 説明 |
|--------|------|------|
| id | bigint | PK |
| name | string | 種別名 |
| display_order | integer | 表示順 |
| active | boolean | 有効フラグ |

**初期データ:**
1. 定期訪問
2. 依頼対応
3. 相続発生前相談
4. 相続発生後相談
5. 事業承継相談
6. 財産診断
7. 資産形成
8. その他

#### visit_plans（訪問計画）

| カラム | 型 | 説明 |
|--------|------|------|
| id | bigint | PK |
| customer_id | bigint | FK |
| user_id | bigint | FK（計画作成者） |
| visit_type_id | bigint | FK |
| planned_date | date | 訪問予定日 |
| planned_time | time | 訪問予定時刻（任意） |
| purpose | text | 訪問目的 |
| status | enum | scheduled（予定）, completed（完了）, cancelled（中止） |
| visit_record_id | bigint | FK（実績紐付け、完了時） |
| created_at | datetime | |
| updated_at | datetime | |

#### visit_records（訪問記録）

| カラム | 型 | 説明 |
|--------|------|------|
| id | bigint | PK |
| customer_id | bigint | FK |
| user_id | bigint | FK（記録者） |
| visit_type_id | bigint | FK |
| visited_at | datetime | 訪問日時 |
| interviewee | string | 面談相手（世帯主本人/配偶者/子など） |
| content | text | 折衝内容（50字以上必須） |
| customer_situation | text | 顧客の状況・反応 |
| visit_plan_id | bigint | FK（計画からの実績の場合） |
| created_at | datetime | |
| updated_at | datetime | |

※ 添付ファイルは Active Storage で管理

#### actions（次アクション）

| カラム | 型 | 説明 |
|--------|------|------|
| id | bigint | PK |
| visit_record_id | bigint | FK（発生元の訪問記録） |
| customer_id | bigint | FK |
| user_id | bigint | FK（担当者） |
| title | string | アクション内容 |
| due_date | date | 期限 |
| status | enum | pending（未完了）, completed（完了）, cancelled（中止） |
| completed_at | datetime | 完了日時 |
| next_visit_record_id | bigint | FK（完了時に作成された訪問記録） |
| created_at | datetime | |
| updated_at | datetime | |

#### diagnoses（財産診断）

| カラム | 型 | 説明 |
|--------|------|------|
| id | bigint | PK |
| customer_id | bigint | FK |
| user_id | bigint | FK（登録者） |
| diagnosed_on | date | 診断実施日 |
| title | string | タイトル（「2024年度財産診断」など） |
| notes | text | 備考 |
| created_at | datetime | |
| updated_at | datetime | |

※ PDF/PPTファイルは Active Storage で管理

---

## ユーザー権限

| 機能 | system_admin | admin（本店） | branch_manager（支店長） |
|------|:------------:|:-------------:|:------------------------:|
| ユーザー管理 | ✓ | - | - |
| マスタ管理（支店・訪問種別） | ✓ | - | - |
| 全支店データ閲覧 | ✓ | ✓ | - |
| 自支店データ閲覧 | ✓ | ✓ | ✓ |
| 重要取引先 追加/編集/削除 | ✓ | ✓ | - |
| 訪問計画 作成/編集 | ✓ | ✓ | ✓（自支店のみ） |
| 訪問記録 作成/編集 | ✓ | ✓ | ✓（自支店のみ） |
| 家族構成 編集 | ✓ | ✓ | ✓（自支店のみ） |
| 財産診断 アップロード | ✓ | ✓ | ✓（自支店のみ） |
| ダッシュボード（本店） | ✓ | ✓ | - |
| ダッシュボード（支店） | ✓ | ✓ | ✓ |
| CSVインポート | ✓ | ✓ | - |

---

## 画面構成

### 共通

- ヘッダー：ロゴ、ユーザー名、ログアウト
- サイドバー：ナビゲーション（役割に応じて表示項目変更）

### 本店管理者向け画面

1. **本店ダッシュボード** `/admin/dashboard`
   - 支店別訪問率（重要取引先のうち○%訪問済み）
   - 次アクション期限切れ件数
   - 相続相談・事業承継相談の進捗件数
   - 支店ごとの重要取引先数
   - 月間/週間の訪問件数推移グラフ
   - 未訪問30日超の世帯リスト（赤信号表示）

2. **支店一覧** `/admin/branches`
   - 支店コード、支店名、重要取引先数、訪問率

3. **重要取引先一覧（全支店）** `/admin/customers`
   - 検索・フィルタ機能
   - 支店別絞り込み

4. **CSVインポート** `/admin/imports`
   - **JA全顧客マスタインポート** `/admin/imports/ja_customers/new`
     - 36,000件の全顧客データをCSVアップロード
     - 差分更新（新規追加・更新・削除検知）
     - インポート履歴・エラーログ表示
   - **重要取引先インポート** `/admin/imports/customers/new`
     - 顧客番号リストから重要取引先を一括登録
     - ja_customersから基本情報を自動取得

### 支店長向け画面

1. **支店ダッシュボード** `/dashboard`
   - 自支店の重要取引先一覧（訪問状況付き）
   - 今週の訪問予定
   - 期限切れアクション一覧
   - 未訪問30日超アラート

2. **重要取引先一覧** `/customers`
   - 自支店のみ表示
   - 最終訪問日、次アクション期限

3. **重要取引先詳細** `/customers/:id`
   - 基本情報
   - **JA事業取引状況**（金融/共済/営農/葬祭/ガス/不動産のバッジ表示）
   - 家系図（ツリー表示 or リスト表示）
   - 訪問履歴タイムライン
   - 次アクション一覧
   - 財産診断履歴（PDF/PPT表示・ダウンロード）

4. **訪問計画作成** `/customers/:id/visit_plans/new`
   - 訪問予定日、種別、目的

5. **訪問記録作成** `/customers/:id/visit_records/new`
   - 60秒入力UI
   - 訪問日時、種別、面談相手
   - 折衝内容（50字以上バリデーション）
   - 顧客状況
   - 次アクション設定
   - ファイル添付

6. **家族構成編集** `/customers/:id/family_members`
   - 家族メンバー追加/編集/削除
   - 続柄、親子関係の設定
   - **JA顧客番号検索機能**
     - 顧客番号入力 → ja_customersから氏名・住所を自動取得
     - 取引有無の可視化（JA顧客の場合はバッジ表示）

7. **財産診断アップロード** `/customers/:id/diagnoses/new`
   - PDF/PPTアップロード
   - 診断日、タイトル

8. **カレンダー表示** `/calendar`
   - 訪問計画の月間/週間表示
   - iCal出力（外部カレンダー連携用）

### システム管理者向け画面

1. **ユーザー管理** `/system/users`
2. **支店マスタ管理** `/system/branches`
3. **訪問種別マスタ管理** `/system/visit_types`

---

## 開発フェーズ

### Phase 1: 基盤構築（Week 1-2） ✅ 完了

- [x] Rails 8 プロジェクト作成
- [x] Devise認証セットアップ
- [x] ユーザー・支店モデル作成
- [x] 権限管理（Pundit）
- [x] 基本レイアウト（Tailwind CSS）

### Phase 2: 顧客管理（Week 3-4）

- [ ] JA全顧客マスタ（ja_customers）モデル作成
- [ ] JA全顧客CSVインポート機能（36,000件対応）
- [ ] 重要取引先CRUD
- [ ] 重要取引先CSVインポート（顧客番号からja_customers参照）
- [ ] 検索・フィルタ機能
- [ ] 支店別データスコープ

### Phase 3: 訪問管理（Week 5-6）

- [ ] 訪問種別マスタ
- [ ] 訪問計画CRUD
- [ ] 訪問記録CRUD（50字バリデーション）
- [ ] 次アクション管理
- [ ] 計画→実績→次アクションの連携

### Phase 4: 家系図・財産診断（Week 7-8）

- [ ] 家族構成CRUD
- [ ] **JA顧客番号検索・自動入力機能**（Stimulus + Turbo Frame）
- [ ] 家系図表示（ツリー or リスト）
- [ ] 財産診断アップロード
- [ ] Active Storage設定

### Phase 5: ダッシュボード（Week 9-10）

- [ ] 本店ダッシュボード
- [ ] 支店ダッシュボード
- [ ] アラート表示（未訪問30日超、期限切れ）
- [ ] グラフ表示（Chart.js or Chartkick）

### Phase 6: 仕上げ（Week 11-12）

- [ ] カレンダー表示
- [ ] UI/UX改善
- [ ] パフォーマンスチューニング
- [ ] テスト拡充
- [ ] ドキュメント整備

---

## コマンドリファレンス

### 初期セットアップ（ローカル環境）

```bash
# 1. プロジェクト作成
rails new ja-visit-management \
  --database=postgresql \
  --css=tailwind \
  --javascript=esbuild \
  --skip-jbuilder \
  --skip-test

cd ja-visit-management

# 2. Gemfile編集（以下のgemを追加）
# 認証
gem 'devise'

# 権限管理
gem 'pundit'

# ページネーション
gem 'kaminari'

# バックグラウンドジョブ
gem 'good_job'

# Excel読み込み（CSVインポート補助）
gem 'roo'

# 日本語化
gem 'rails-i18n'
gem 'devise-i18n'

# 開発・テスト用
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

# 3. gemインストール
bundle install

# 4. RSpec設定
rails generate rspec:install

# 5. Devise設定
rails generate devise:install
rails generate devise User

# 6. Pundit設定
rails generate pundit:install

# 7. GoodJob設定
rails generate good_job:install

# 8. データベース作成
rails db:create
rails db:migrate

# 9. サーバー起動
bin/dev
```

---

## 注意事項

### セキュリティ

- 個人情報を扱うため、本番環境ではSSL必須
- Excel出力機能は実装しない（内部統制上の理由）
- ログイン試行回数制限（Devise Lockable）

### パフォーマンス

- 15,000世帯規模を想定したインデックス設計
- **ja_customers（36,000件）の顧客番号検索は数ミリ秒で完了**
- 訪問記録・アクションの一覧はページネーション必須
- 最終訪問日は customers テーブルにキャッシュ
- JA全顧客CSVインポートはバックグラウンドジョブ（GoodJob）で実行

### 将来的な拡張

- Active Directory連携（devise_ldap_authenticatable）
- SQL Server対応（sqlserver adapter）
- メール通知機能
- モバイル対応（PWA化）

#### 事業横断の顧客管理（Phase 2以降）

現状、JA各事業（金融・共済・営農・葬祭・ガス・不動産）で顧客番号が統一されていないため、
まずはフラグ方式で「どの事業と取引があるか」を可視化する。

**Step 1: フラグ方式（現在の設計）**
```
ja_customers
├─ has_banking: true      # 金融取引あり
├─ has_mutual_aid: true   # 共済加入あり
├─ has_agriculture: true  # 営農取引あり
├─ has_funeral: false     # 葬祭なし
├─ has_gas: false         # ガスなし
└─ has_real_estate: false # 不動産なし
```

**Step 2: 事業別詳細テーブル（将来拡張）**

顧客番号の名寄せが進んだ段階で、詳細情報を管理するテーブルを追加：

```
mutual_aid_contracts（共済契約）
├─ ja_customer_id
├─ contract_type: 建更/自動車/生命/医療/年金
├─ contract_amount
└─ expiry_date

agriculture_transactions（営農取引）
├─ ja_customer_id
├─ crop_type: 水稲/野菜/果樹
├─ cultivation_area
└─ annual_shipment_amount
```

**活用イメージ**
- 重要取引先詳細画面で「この世帯のJA取引全体像」を表示
- 相続相談時に「共済の受取人確認」「営農の後継者」を一覧把握
- クロスセル機会の発見（金融のみ→共済提案など）

---

## 予約システム連携

### 概要

本システム（訪問管理）と別途開発中の「相談予約システム」を連携し、
顧客接点の全体像を把握できるようにする。

```
┌─────────────────────────────────────────────────────────────┐
│                    顧客接点の統合管理                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  【予約システム】              【訪問管理システム】          │
│   インバウンド                  アウトバウンド               │
│   （顧客→JA）                  （JA→顧客）                 │
│                                                             │
│   ・相続相談予約               ・重要取引先訪問              │
│   ・来店予約                   ・訪問計画・記録              │
│   ・オンライン相談             ・次アクション管理            │
│                                                             │
│            ↓↑ 顧客番号で連携 ↓↑                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ 統合ダッシュボード（将来構想）                        │  │
│  │ ・顧客接点履歴（来店+訪問）の一元表示                │  │
│  │ ・相続発生アラートの共有                             │  │
│  │ ・未接点顧客の可視化                                 │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 連携キー

**顧客番号（customer_number）** を共通キーとして使用。
両システムで同一の顧客番号体系を採用することで、データ連携を可能にする。

### 連携メリット

| メリット | 詳細 |
|----------|------|
| **相続発生の早期把握** | 予約システムで「相続発生後相談」が入った瞬間に、訪問管理側で該当顧客にフラグ立て。家系図確認→訪問計画作成がスムーズに |
| **訪問後のフォロー予約** | 訪問で財産診断実施後、「次回来店で詳細説明」を次アクション登録→予約システムで来店予約を作成 |
| **顧客接点の一元把握** | 本店ダッシュボードで「来店履歴+訪問履歴」を時系列表示。接点の抜け漏れを防止 |
| **重要取引先の来店時アラート** | 予約が入った顧客が重要取引先の場合、「直近の訪問記録」を予約システム側に表示。来店対応の質向上 |
| **未接点顧客の発見** | 訪問も来店予約もない重要取引先を自動検出→要アプローチリストに追加 |

### 連携パターン

| パターン | 難易度 | 特徴 | 採用シーン |
|----------|:------:|------|------------|
| **A. 共有DB** | 低 | 同一PostgreSQLに両システムのテーブルを配置。リアルタイム連携 | 同一サーバーで運用する場合 |
| **B. API連携** | 中 | REST APIで相互にデータ取得。システム独立性が高い | 別サーバーで運用する場合 |
| **C. 定期CSV連携** | 低 | 日次/週次でCSV出力→インポート。既存運用に近い | 段階的導入、疎結合を維持したい場合 |

### 実装案（共有DBパターン）

```ruby
# 訪問管理システム側：予約情報の参照
class Customer < ApplicationRecord
  # 予約システムのテーブルを参照（同一DB内）
  def reservations
    Reservation.where(customer_number: customer_number)
               .order(reserved_at: :desc)
  end

  def recent_reservations(limit: 5)
    reservations.limit(limit)
  end

  def has_upcoming_reservation?
    reservations.where('reserved_at > ?', Time.current).exists?
  end
end

# 予約システム側：重要取引先情報の参照
class Reservation < ApplicationRecord
  def important_customer
    Customer.find_by(customer_number: customer_number)
  end

  def important_customer?
    important_customer.present?
  end

  def recent_visit_records
    return [] unless important_customer
    important_customer.visit_records.recent.limit(3)
  end
end
```

### 連携テーブル（将来追加）

予約システムとの連携が本格化した際に追加するビューまたはテーブル：

```sql
-- 顧客接点履歴ビュー（統合ダッシュボード用）
CREATE VIEW customer_touchpoints AS
SELECT
  customer_number,
  'visit' AS touchpoint_type,
  visited_at AS touchpoint_at,
  visit_types.name AS touchpoint_detail
FROM visit_records
JOIN visit_types ON visit_records.visit_type_id = visit_types.id

UNION ALL

SELECT
  customer_number,
  'reservation' AS touchpoint_type,
  reserved_at AS touchpoint_at,
  consultation_types.name AS touchpoint_detail
FROM reservations
JOIN consultation_types ON reservations.consultation_type_id = consultation_types.id

ORDER BY touchpoint_at DESC;
```

### 連携ロードマップ

| Phase | 内容 | 時期 |
|-------|------|------|
| **Phase A** | 両システム単独稼働、顧客番号体系の統一確認 | 現在 |
| **Phase B** | 予約システム側で「重要取引先バッジ」表示 | 予約システム本番稼働後 |
| **Phase C** | 訪問管理側で「直近の来店予約」表示 | Phase B完了後 |
| **Phase D** | 統合ダッシュボード（顧客接点履歴の一元表示） | 両システム安定稼働後 |

### 注意事項

- 連携開始前に、両システムの顧客番号が同一体系であることを確認
- 個人情報保護の観点から、連携するデータ項目は必要最小限に
- 連携障害時の縮退運用（各システム単独で動作可能な設計）を維持
