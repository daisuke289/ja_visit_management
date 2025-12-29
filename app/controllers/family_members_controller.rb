# frozen_string_literal: true

class FamilyMembersController < ApplicationController
  before_action :set_customer
  before_action :set_family_member, only: [ :edit, :update, :destroy ]

  def index
    @family_members = @customer.family_members.ordered_by_generation
    authorize @customer, :show?
  end

  def new
    @family_member = @customer.family_members.build
    @family_member.is_living = true
    authorize @family_member
  end

  def create
    @family_member = @customer.family_members.build(family_member_params)
    authorize @family_member

    if @family_member.save
      redirect_to customer_family_members_path(@customer), notice: "家族メンバーを登録しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @family_member
  end

  def update
    authorize @family_member

    if @family_member.update(family_member_params)
      redirect_to customer_family_members_path(@customer), notice: "家族メンバーを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @family_member

    @family_member.destroy
    redirect_to customer_family_members_path(@customer), notice: "家族メンバーを削除しました。"
  end

  private

  def set_customer
    @customer = accessible_customers.find(params[:customer_id])
  end

  def set_family_member
    @family_member = @customer.family_members.find(params[:id])
  end

  def family_member_params
    params.require(:family_member).permit(
      :name, :name_kana, :birth_date, :relationship, :relationship_type,
      :generation, :is_living, :is_cohabitant, :address, :phone,
      :occupation, :workplace, :ja_customer_number, :notes,
      :parent_member_id, :spouse_member_id, :marriage_status
    )
  end
end
