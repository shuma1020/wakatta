class AccountsController < ApplicationController
  before_action :login_required
  def show
    @member = current_member
  end

  def edit
    @member = current_member
  end

  def update
    @member =current_member
    if @member.update(member_params)
      redirect_to :account, notice: "アカウント情報を更新しました。"
    else
      render "edit"
    end
  end

  private
  def member_params
    params.require(:member).permit(:name, :email, :birthday, :password)
  end
end
