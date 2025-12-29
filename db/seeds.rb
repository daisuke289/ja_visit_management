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
  # サンプル支店
  branch = Branch.find_or_create_by!(code: '001') do |b|
    b.name = '本店'
  end

  branch2 = Branch.find_or_create_by!(code: '002') do |b|
    b.name = '東支店'
  end

  branch3 = Branch.find_or_create_by!(code: '003') do |b|
    b.name = '西支店'
  end

  puts "支店マスタを作成しました（#{Branch.count}件）"

  # システム管理者
  User.find_or_create_by!(email: 'admin@example.com') do |u|
    u.password = 'password123'
    u.name = 'システム管理者'
    u.role = :system_admin
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
    u.name = '東支店 花子'
    u.role = :branch_manager
    u.branch = branch2
  end

  puts "開発用ユーザーを作成しました（#{User.count}件）"
  puts "  - admin@example.com / password123 (システム管理者)"
  puts "  - honten@example.com / password123 (本店管理者)"
  puts "  - branch@example.com / password123 (支店長)"

  # サンプルJA全顧客
  [
    { customer_number: 'JA001', name: '山田 太郎', name_kana: 'ヤマダ タロウ', branch: branch2,
      has_banking: true, has_mutual_aid: true, has_agriculture: false },
    { customer_number: 'JA002', name: '佐藤 花子', name_kana: 'サトウ ハナコ', branch: branch2,
      has_banking: true, has_mutual_aid: false, has_agriculture: true },
    { customer_number: 'JA003', name: '鈴木 一郎', name_kana: 'スズキ イチロウ', branch: branch3,
      has_banking: true, has_mutual_aid: true, has_agriculture: true },
    { customer_number: 'JA004', name: '田中 次郎', name_kana: 'タナカ ジロウ', branch: branch2,
      has_banking: true, has_mutual_aid: true, has_funeral: true },
    { customer_number: 'JA005', name: '高橋 三郎', name_kana: 'タカハシ サブロウ', branch: branch3,
      has_banking: true, has_gas: true, has_real_estate: true },
  ].each do |attrs|
    JaCustomer.find_or_create_by!(customer_number: attrs[:customer_number]) do |c|
      c.name = attrs[:name]
      c.name_kana = attrs[:name_kana]
      c.branch = attrs[:branch]
      c.address = '東京都渋谷区1-2-3'
      c.phone = '03-1234-5678'
      c.has_banking = attrs[:has_banking] || false
      c.has_mutual_aid = attrs[:has_mutual_aid] || false
      c.has_agriculture = attrs[:has_agriculture] || false
      c.has_funeral = attrs[:has_funeral] || false
      c.has_gas = attrs[:has_gas] || false
      c.has_real_estate = attrs[:has_real_estate] || false
      c.deposit_balance = rand(100000..10000000)
      c.last_synced_at = Time.current
    end
  end

  puts "JA全顧客サンプルを作成しました（#{JaCustomer.count}件）"

  # サンプル重要取引先
  [
    { customer_number: 'JA001', name: '山田 太郎', branch: branch2, last_visit_date: 10.days.ago },
    { customer_number: 'JA002', name: '佐藤 花子', branch: branch2, last_visit_date: 45.days.ago },
    { customer_number: 'JA003', name: '鈴木 一郎', branch: branch3, last_visit_date: nil },
  ].each do |attrs|
    Customer.find_or_create_by!(customer_number: attrs[:customer_number]) do |c|
      c.name = attrs[:name]
      c.name_kana = JaCustomer.find_by(customer_number: attrs[:customer_number])&.name_kana
      c.branch = attrs[:branch]
      c.address = '東京都渋谷区1-2-3'
      c.phone = '03-1234-5678'
      c.last_visit_date = attrs[:last_visit_date]
    end
  end

  puts "重要取引先サンプルを作成しました（#{Customer.count}件）"
end
