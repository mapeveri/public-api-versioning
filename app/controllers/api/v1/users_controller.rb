class Api::V1::UsersController < ApplicationController
  before_action :set_user, only: [ :show, :update, :destroy ]

  # GET /api/v1/users
  def index
    users = User.all
    version = ApiVersion.from_request(request)
    serialized = ActiveModelSerializers::SerializableResource.new(users).as_json
    transformed = serialized.map { |u| ApiTransformations::UserTransformations.transform(u, version) }
    render json: transformed
  end

  # GET /api/v1/users/:id
  def show
    version = ApiVersion.from_request(request)
    serialized = UserSerializer.new(@user).as_json
    transformed = ApiTransformations::UserTransformations.transform(serialized, version)
    render json: transformed
  end

  # POST /api/v1/users
  def create
    user = User.new(user_params)
    if user.save
      version = ApiVersion.from_request(request)
      serialized = UserSerializer.new(user).as_json
      transformed = ApiTransformations::UserTransformations.transform(serialized, version)
      render json: transformed, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/users/:id
  def update
    if @user.update(user_params)
      version = ApiVersion.from_request(request)
      serialized = UserSerializer.new(@user).as_json
      transformed = ApiTransformations::UserTransformations.transform(serialized, version)
      render json: transformed
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/users/:id
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
