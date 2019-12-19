class MembersController < ApplicationController
    before_action :login_required
    def index
        @members = Member.order("id")
        .page(params[:page]).per(15)
    end

    def show
        @member = Member.find(params[:id])
    end


end