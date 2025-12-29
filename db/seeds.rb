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
end
