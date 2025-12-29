# frozen_string_literal: true

class ActionsController < ApplicationController
  before_action :set_customer
  before_action :set_action, only: [ :update, :destroy, :complete, :cancel ]

  def create
    @visit_record = @customer.visit_records.find(params[:visit_record_id])
    @action = @visit_record.actions.build(action_params)
    @action.customer = @customer
    @action.user = current_user
    @action.status = :pending
    authorize @action

    if @action.save
      redirect_to customer_visit_record_path(@customer, @visit_record), notice: "次アクションを登録しました。"
    else
      redirect_to customer_visit_record_path(@customer, @visit_record), alert: @action.errors.full_messages.join(", ")
    end
  end

  def update
    authorize @action

    if @action.update(action_params)
      respond_to do |format|
        format.html { redirect_to customer_path(@customer), notice: "アクションを更新しました。" }
        format.turbo_stream
      end
    else
      redirect_to customer_path(@customer), alert: @action.errors.full_messages.join(", ")
    end
  end

  def destroy
    authorize @action

    @action.destroy
    redirect_to customer_path(@customer), notice: "アクションを削除しました。"
  end

  def complete
    authorize @action, :update?

    @action.complete!
    respond_to do |format|
      format.html { redirect_to customer_path(@customer), notice: "アクションを完了しました。" }
      format.turbo_stream
    end
  end

  def cancel
    authorize @action, :update?

    @action.cancel!(reason: params[:reason])
    respond_to do |format|
      format.html { redirect_to customer_path(@customer), notice: "アクションを中止しました。" }
      format.turbo_stream
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end

  def set_action
    @action = @customer.actions.find(params[:id])
  end

  def action_params
    params.require(:action_record).permit(:title, :due_date, :user_id)
  end
end
