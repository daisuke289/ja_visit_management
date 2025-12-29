# frozen_string_literal: true

class DiagnosesController < ApplicationController
  before_action :set_customer
  before_action :set_diagnosis, only: [ :show, :edit, :update, :destroy ]

  def index
    @diagnoses = @customer.diagnoses.recent
    authorize @customer, :show?
  end

  def show
    authorize @diagnosis
  end

  def new
    @diagnosis = @customer.diagnoses.build
    @diagnosis.diagnosed_on = Date.current
    authorize @diagnosis
  end

  def create
    @diagnosis = @customer.diagnoses.build(diagnosis_params)
    @diagnosis.user = current_user
    authorize @diagnosis

    if @diagnosis.save
      redirect_to customer_diagnosis_path(@customer, @diagnosis), notice: "財産診断を登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @diagnosis
  end

  def update
    authorize @diagnosis

    if @diagnosis.update(diagnosis_params)
      redirect_to customer_diagnosis_path(@customer, @diagnosis), notice: "財産診断を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @diagnosis

    @diagnosis.document.purge if @diagnosis.document.attached?
    @diagnosis.destroy
    redirect_to customer_diagnoses_path(@customer), notice: "財産診断を削除しました。"
  end

  private

  def set_customer
    @customer = accessible_customers.find(params[:customer_id])
  end

  def set_diagnosis
    @diagnosis = @customer.diagnoses.find(params[:id])
  end

  def diagnosis_params
    params.require(:diagnosis).permit(:diagnosed_on, :title, :notes, :document)
  end
end
