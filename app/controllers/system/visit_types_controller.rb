# frozen_string_literal: true

class System::VisitTypesController < ApplicationController
  before_action :set_visit_type, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize VisitType
    @visit_types = VisitType.ordered
  end

  def new
    @visit_type = VisitType.new
    @visit_type.display_order = (VisitType.maximum(:display_order) || 0) + 1
    authorize @visit_type
  end

  def create
    @visit_type = VisitType.new(visit_type_params)
    authorize @visit_type

    if @visit_type.save
      redirect_to system_visit_types_path, notice: "訪問種別を登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @visit_type
  end

  def update
    authorize @visit_type

    if @visit_type.update(visit_type_params)
      redirect_to system_visit_types_path, notice: "訪問種別を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @visit_type

    if @visit_type.visit_plans.exists? || @visit_type.visit_records.exists?
      redirect_to system_visit_types_path, alert: "この訪問種別は使用されているため削除できません。"
    else
      @visit_type.destroy
      redirect_to system_visit_types_path, notice: "訪問種別を削除しました。"
    end
  end

  private

  def set_visit_type
    @visit_type = VisitType.find(params[:id])
  end

  def visit_type_params
    params.require(:visit_type).permit(:name, :display_order, :active)
  end
end
