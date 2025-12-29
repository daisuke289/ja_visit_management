import { Controller } from "@hotwired/stimulus"

// JA顧客番号検索コントローラー
// 家族構成入力時にJA全顧客マスタから情報を取得する
export default class extends Controller {
  static targets = ["input", "result"]

  async search() {
    const customerNumber = this.inputTarget.value.trim()

    if (!customerNumber) {
      this.showError("顧客番号を入力してください")
      return
    }

    try {
      const response = await fetch(`/ja_customers/search?customer_number=${encodeURIComponent(customerNumber)}`, {
        headers: {
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!response.ok) {
        throw new Error("検索に失敗しました")
      }

      const data = await response.json()

      if (data.found) {
        this.showResult(data.customer)
      } else {
        this.showError(data.message || "該当する顧客が見つかりません")
      }
    } catch (error) {
      console.error("JA顧客検索エラー:", error)
      this.showError("検索中にエラーが発生しました")
    }
  }

  showResult(customer) {
    const businessBadges = customer.business_summary
      ? customer.business_summary.split("、").map(b =>
          `<span class="bg-green-100 text-green-800 text-xs px-2 py-0.5 rounded">${b}</span>`
        ).join(" ")
      : '<span class="text-gray-400">取引情報なし</span>'

    this.resultTarget.innerHTML = `
      <div class="bg-green-50 border border-green-200 rounded-lg p-4">
        <div class="flex justify-between items-start">
          <div>
            <h4 class="font-medium text-green-800">顧客情報を取得しました</h4>
            <dl class="mt-2 grid grid-cols-2 gap-2 text-sm">
              <div>
                <dt class="text-gray-500">氏名</dt>
                <dd class="font-medium">${customer.name}</dd>
              </div>
              <div>
                <dt class="text-gray-500">氏名カナ</dt>
                <dd class="font-medium">${customer.name_kana || '-'}</dd>
              </div>
              <div>
                <dt class="text-gray-500">生年月日</dt>
                <dd class="font-medium">${customer.birth_date || '-'}</dd>
              </div>
              <div>
                <dt class="text-gray-500">取引支店</dt>
                <dd class="font-medium">${customer.branch_name || '-'}</dd>
              </div>
              <div class="col-span-2">
                <dt class="text-gray-500">住所</dt>
                <dd class="font-medium">${customer.address || '-'}</dd>
              </div>
              <div class="col-span-2">
                <dt class="text-gray-500">JA事業取引</dt>
                <dd class="flex flex-wrap gap-1 mt-1">${businessBadges}</dd>
              </div>
            </dl>
          </div>
          <button type="button"
              class="text-green-600 hover:text-green-800"
              data-action="click->ja-customer-search#applyData"
              data-customer='${JSON.stringify(customer)}'>
            この情報を適用
          </button>
        </div>
      </div>
    `
    this.resultTarget.classList.remove("hidden")
  }

  showError(message) {
    this.resultTarget.innerHTML = `
      <div class="bg-red-50 border border-red-200 rounded-lg p-4">
        <p class="text-red-800">${message}</p>
      </div>
    `
    this.resultTarget.classList.remove("hidden")
  }

  applyData(event) {
    const customer = JSON.parse(event.currentTarget.dataset.customer)
    const form = this.element.closest("form")

    // フォームのフィールドに値を自動入力
    const fields = {
      "family_member_name": customer.name,
      "family_member_name_kana": customer.name_kana,
      "family_member_birth_date": customer.birth_date,
      "family_member_address": customer.address,
      "family_member_phone": customer.phone
    }

    Object.entries(fields).forEach(([name, value]) => {
      const input = form.querySelector(`[name="family_member[${name.replace('family_member_', '')}]"]`)
      if (input && value) {
        input.value = value
        // 変更イベントを発火
        input.dispatchEvent(new Event("change", { bubbles: true }))
      }
    })

    // 適用完了メッセージ
    this.resultTarget.innerHTML = `
      <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <p class="text-blue-800">顧客情報をフォームに適用しました</p>
      </div>
    `
  }
}
