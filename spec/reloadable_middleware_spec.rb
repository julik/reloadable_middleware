RSpec.describe ReloadableMiddleware do
  it "has a version number" do
    expect(ReloadableMiddleware::VERSION).not_to be nil
  end

  it "wraps a given module with a reloading class, giving it a sensible to_s return value" do
    class MiddlewareWithArguments
      def initialize(app, frobnicate:)
        @app = app
        @frobnicate = frobnicate
      end

      def call(env)
        raise "Should not call the same middleware object for the second time" if @got_called
        @got_called = :yes

        env['did_pass_middleware1'] = true
        env['frobnicate'] = @frobnicate
        @app.call(env)
      end
    end

    class MiddlewareWithoutArguments
      def initialize(app)
        @app = app
      end

      def call(env)
        raise "Should not call the same middleware object for the second time" if @got_called
        @got_called = :yes

        env['did_pass_middleware2'] = true
        @app.call(env)
      end
    end

    reloadable_class = ReloadableMiddleware.wrap(MiddlewareWithArguments)
    expect(reloadable_class.to_s).to include('MiddlewareWithArguments')

    rack_app = ->(env) {
      expect(env['did_pass_middleware1']).to eq(true)
      expect(env['did_pass_middleware2']).to eq(true)
      expect(env['frobnicate']).to eq('totally')
    }
    expect(rack_app).to receive(:call).twice.and_call_original

    reloadable_class2 = ReloadableMiddleware.wrap(MiddlewareWithoutArguments)

    # Build out a tiny Rack app stack
    mounted_middleware = reloadable_class2.new(reloadable_class.new(rack_app, frobnicate: 'totally'))

    # ...and call into it, twice. If our middleware objects were retained (as they are with standard
    # Rack wrapping process) we will get an exception, since these particular middleware objects
    # will only tolerate being called once.
    mounted_middleware.call({})
    mounted_middleware.call({})
  end

  it 'turns wrap() into a no-op if RACK_ENV is set to "production"' do
    class SomeMiddleware
    end

    ENV['RACK_ENV'] = 'production'
    wrapped = ReloadableMiddleware.wrap(SomeMiddleware)
    expect(wrapped).to eq(SomeMiddleware)

    ENV.delete('RACK_ENV')
  end
end
