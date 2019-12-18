class MembersController < ApplicationController
    before_action :login_required
    def index
        @members = Member.order("id")
        .page(params[:page]).per(15)
    end

    def show
        @member = Member.find(params[:id])
    end

    def new
        @member = Member.new(birthday: Date.new(1980,1,1))
    end

end