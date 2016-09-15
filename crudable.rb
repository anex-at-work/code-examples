module Crudable
  extend ActiveSupport::Concern
  include Scopable

  included do
    scope = __scope
    methods = {}
    %w(load new).each do |s|
      methods[%(#{s}_scope).to_sym] = %(#{s}_#{scope}).to_sym
    end
    before_filter methods[:load_scope], only: [:show, :edit, :update, :destroy]
    before_filter methods[:new_scope], only: :new

    define_method methods[:load_scope] do
      instance_variable_set %(@#{scope}), scope.camelize.constantize.find(params[:id])
    end
    private methods[:load_scope]

    define_method methods[:new_scope] do
      instance_variable_set %(@#{scope}), scope.camelize.constantize.new
    end
    private methods[:new_scope]
  end

  def new
  end

  def edit
  end

  def destroy
    scope = self.class.send :__scope
    scope_var = instance_variable_get %(@#{scope}).to_sym
    scope_var.deactivate
    reload_js
  end

  def create
    scope = self.class.send :__scope
    __check_params
    scope_var = instance_variable_set %(@#{scope}),
      scope.camelize.constantize.create(method(%(#{scope}_params).to_sym).call)
    if !scope_var.valid?
      render action: :new
    else
      yield scope_var if block_given?
      scope_var.save
      redirect_after
    end
  end

  def update
    scope = self.class.send :__scope
    __check_params
    scope_var = instance_variable_get %(@#{scope}).to_sym
    scope_var.update method(%(#{scope}_params).to_sym).call
    if !scope_var.valid?
      render action: :edit
    else
      yield scope_var if block_given?
      redirect_after
    end
  end

  def redirect_after
    if !params[:commit].nil?
      redirect_to action: :index
    else
      redirect_to action: :edit, id: instance_variable_get(%(@#{self.class.send :__scope})).id
    end
  end

  def reload_js
    render js: %($(document).trigger('data:reload'))
  end

  private
  def __check_params
    scope = self.class.send :__scope
    if !respond_to? %(#{scope}_params), true
      raise NoMethodError.new %(undefined method '#{scope}_params' for #{inspect}:#{self.class})
    end
  end
end
