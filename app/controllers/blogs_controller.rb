# frozen_string_literal: true

class BlogsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  before_action :set_blog, only: %i[show edit update destroy]

  before_action :authorize_user!, only: %i[edit update destroy]

  before_action :authorize_blog_view!, only: %i[show]

  def index
    @blogs = Blog.search(params[:term]).published.default_order
  end

  def show; end

  def new
    @blog = Blog.new
  end

  def edit; end

  def create
    if invalid_random_eyecatch_request?
      render status: :bad_request, plain: 'Bad Request'
      return
    end

    @blog = current_user.blogs.new(blog_params)

    if @blog.save
      redirect_to blog_url(@blog), notice: 'Blog was successfully created.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if invalid_random_eyecatch_request?
      render status: :bad_request, plain: 'Bad Request'
      return
    end

    if @blog.update(blog_params)
      redirect_to blog_url(@blog), notice: 'Blog was successfully updated.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @blog.destroy!

    redirect_to blogs_url, notice: 'Blog was successfully destroyed.', status: :see_other
  end

  private

  def set_blog
    @blog = Blog.find(params[:id])
  end

  def blog_params
    permitted = %i[title content secret]
    permitted << :random_eyecatch if current_user.premium?

    params.expect(blog: permitted)
  end

  def authorize_user!
    return if @blog.owned_by?(current_user)

    raise ActiveRecord::RecordNotFound
  end

  def invalid_random_eyecatch_request?
    eyecatch_requested = params.dig(:blog, :random_eyecatch).present?
    premium_user = current_user.premium?

    eyecatch_requested && !premium_user
  end

  def authorize_blog_view!
    return unless @blog.secret?

    return if @blog.owned_by?(current_user)

    raise ActiveRecord::RecordNotFound
  end
end
