# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :redirect_to_localized, unless: -> { params[:locale] }
  before_action :set_params_hash
  before_action :set_locale
  before_action :redirect_to_slug_if_name
  before_action :set_default_branch
  before_action :authorizer_for_profiler

  helper_method :sort_column, :sort_order, :sort_order_next

  def default_url_options(_options = {})
    { locale: I18n.locale }
  end

  def sort_column
    ['status', 'name', 'age'].include?(params[:sort]) ? params[:sort] : 'name'
  end

  def sort_order
    ['asc', 'desc'].include?(params[:order]) ? params[:order] : 'asc'
  end

  def sort_order_next(column)
    return 'desc' if params[:order] == 'asc' && params[:sort] == column
    return 'asc' if params[:order] == 'desc' && params[:sort] == column
    'asc'
  end

  def authorizer_for_profiler
    Rack::MiniProfiler.authorize_request if current_user.try(:admin?)
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    Rails.logger.error "E: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"

    render status: 404, file: "#{ Rails.root }/public/404.html", layout: false
  end

  rescue_from ActionController::BadRequest do
    Rails.logger.error "E: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"

    redirect_to root_url
  end

  protected

  def redirect_to_localized
    redirect_to(url_for(request.query_parameters.merge(locale: prefered_locale)))
  end

  def set_locale
    I18n.locale = FastGettext.locale = params[:locale]
  end

  def redirect_to_slug_if_name
     if named_branch = Branch.where(name: params[:branch]).where.not(slug: params[:branch]).first
        redirect_to(url_for(request.query_parameters.merge(branch: named_branch.slug)))
     end
  end

  def set_default_branch
     @branch = Branch.find_by!(slug: params[:branch].blank? && 'sisyphus' || params[:branch]).decorate
     @default_branch = @branch
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "E: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"

    redirect_to root_path
  end

  def prefered_locale
    return if browser.bot?

    http_accept_language.compatible_language_from(I18n.available_locales) || 'en'
  end

  def set_params_hash
     @get_params = params.permit(:controller, :action, :locale, :branch, :page).to_h
  end
end
