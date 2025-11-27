class Api::V2::UsersController < ApplicationController
  before_action :set_user, only: [ :show, :update, :destroy ]

  # GET /api/v2/users
  def index
    users = User.all
    serialized = ActiveModelSerializers::SerializableResource.new(users).as_json
    render json: serialized
  end

  # GET /api/v2/users/:id
  def show
    serialized = UserSerializer.new(@user).as_json
    render json: serialized
  end

  # POST /api/v2/users
  def create
    user = User.new(user_params)
    if user.save
      serialized = UserSerializer.new(user).as_json
      render json: serialized, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v2/users/:id
  def update
    if @user.update(user_params)
      serialized = UserSerializer.new(@user).as_json
      render json: serialized
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v2/users/:id
  def destroy
    @user.destroy
    head :no_content
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end
end
