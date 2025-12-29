class JaCustomersController < ApplicationController
  # JA全顧客の検索API（家族構成入力時に使用）

  def index
    @ja_customers = policy_scope(JaCustomer)
                      .includes(:branch)
                      .order(:name_kana)

    if params[:q].present?
      @ja_customers = @ja_customers.search(params[:q])
    end

    @ja_customers = @ja_customers.page(params[:page]).per(20)
  end

  def show
    @ja_customer = JaCustomer.find(params[:id])
    authorize @ja_customer
  end

  # Ajax検索（顧客番号から情報取得）
  def search
    authorize JaCustomer, :search?

    if params[:customer_number].present?
      @ja_customer = accessible_ja_customers.find_by(customer_number: params[:customer_number])

      if @ja_customer
        render json: {
          found: true,
          customer: {
            customer_number: @ja_customer.customer_number,
            name: @ja_customer.name,
            name_kana: @ja_customer.name_kana,
            birth_date: @ja_customer.birth_date&.strftime('%Y-%m-%d'),
            postal_code: @ja_customer.postal_code,
            address: @ja_customer.address,
            phone: @ja_customer.phone,
            branch_name: @ja_customer.branch&.name,
            business_summary: @ja_customer.business_summary
          }
        }
      else
        render json: { found: false, message: '該当する顧客が見つかりません' }
      end
    else
      # キーワード検索
      query = params[:q].to_s.strip
      if query.length >= 2
        customers = accessible_ja_customers.search(query).limit(10)
        render json: {
          results: customers.map { |c|
            {
              customer_number: c.customer_number,
              name: c.name,
              name_kana: c.name_kana,
              address: c.address
            }
          }
        }
      else
        render json: { results: [] }
      end
    end
  end
end
