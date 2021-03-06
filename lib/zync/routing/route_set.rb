require 'rack/mount'

module Zync
  module Routing
    class RouteSet
      PARAMETERS_KEY = 'zync.request.path_parameters'

      class Dispatcher

        def initialize(options={})
          @controllers = {}
        end

        def call(env)
          params = env[PARAMETERS_KEY]
          params[:action] ||= 'index' # Default action to index

          unless controller = controller(params)
            return [404, {'X-Cascade' => 'pass'}, ["Not Found"]]
          end

          dispatch(controller, params[:action], env)
        end

        def controller(params)
          if params && params.key?(:controller)
            controller_param = params[:controller]
            controller_reference(controller_param)
          end
        rescue NameError => e
          raise  e # TODO: raise Zync::RoutingError
        end

        private

          def controller_reference(controller_param)
            unless controller = @controllers[controller_param]
              controller_name = "#{controller_param.camelize}Controller"           
              controller = @controllers[controller_param] = ActiveSupport::Dependencies.ref(controller_name)              
            end
            controller.get
          end

          def dispatch(controller, action, env)
            controller.action(action).call(env)
          end

      end

      attr_accessor :set, :routes, :request_class

      def initialize(request_class = Rack::Request)
        self.routes = []
        self.request_class = request_class # Used by Rack::Mount
        self.clear!
      end

      def add_route(app, conditions = {}, defaults = {})
        route = Zync::Routing::Route.new(app, conditions, defaults)
        @set.add_route(*route)
        self.routes << route
        route
      end

      def call(env)
        freeze!
        @set.call(env)
      end

      # Clear all routes
      def clear!
        @routes_frozen = false
        routes.clear        
        @set = ::Rack::Mount::RouteSet.new(
          :parameters_key => PARAMETERS_KEY,
          :request_class  => request_class
        )
        # Add Empty favicon to route set
        @set.add_route(proc {|env| [200, {}, []] }, { :path_info => '/favicon.ico' }, {})
      end

      def draw(&block)
        mapper = Mapper.new(self)
        mapper.instance_exec(&block)
      end
      
      private

        # Freeze all routes
        def freeze!
          return if @routes_frozen
          @routes_frozen = true
          @set.freeze
        end
        
    end
  end
end
