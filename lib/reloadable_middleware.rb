require_relative "reloadable_middleware/version"

module ReloadableMiddleware
  # Base class for the reloadable middleware. We need to save
  # the middleware name somewhere, so this class will be
  # subclassed dynamically and preconfigured with the
  # correct middleware name, to be used by its `.to_s` return value
  class Lazy
    # Saves the app and the arguments for configuring the middleware and applies them
    # when `call()` gets called.
    def initialize(app, *args_for_middleware_new, &block_for_middleware_new)
      @app = app
      @args_for_middleware_new = args_for_middleware_new
      @block_for_middleware_new = block_for_middleware_new.to_proc if block_for_middleware_new
    end

    # Instantiate the given middleware by name, on the spot, and call() it immediately
    def call(env)
      middleware_module = lookup_middleware_module
      app_wrapped_with_middleware = middleware_module.new(@app, *@args_for_middleware_new, &@block_for_middleware_new)
      app_wrapped_with_middleware.call(env) 
    end

    # This is needed since Rails, for instance, calls "to_s" on the middleware
    # class when showing its middleware list. The output also is valid Ruby code,
    # so we need to print something that can be pasted into code again. 
    def self.to_s
      "ReloadableMiddleware.wrap(#{@middleware_name})"
    end

    private

    def lookup_middleware_module
      middleware_module_name = self.class.instance_variable_get('@middleware_name')
      # Rails constantize() on the cheap
      middleware_module_name.split('::').reject(&:empty?).inject(Kernel) {|namespace, const_name| namespace.const_get(const_name) }
    end
  end

  def self.wrap(middleware_class_or_name)
    # Specific case: if the middleware is being _defined_ in production (Rails or bare Rack)
    # instead of making it reloadable return the object itself, since we otherwise churn
    # one instance of the middleware we wrap per request.
    if ENV['RACK_ENV'] == 'production' || defined?(Rails.env) && Rails.env.production?
      return middleware_class_or_name
    else
      middleware_module_name = middleware_class_or_name.to_s
      Class.new(Lazy) { @middleware_name = middleware_module_name }
    end
  end
end

