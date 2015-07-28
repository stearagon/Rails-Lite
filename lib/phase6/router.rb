module Phase6
  class Route
    attr_accessor :pattern, :http_method, :controller_class, :action_name

    def initialize(pattern, http_method, controller_class, action_name)
      @pattern = pattern
      @http_method = http_method
      @controller_class = controller_class
      @action_name = action_name
    end

    # checks if pattern matches path and method matches request method
    def matches?(req)
      req.path.match(@pattern) && req.request_method.downcase == @http_method
    end

    # use pattern to pull out route params (save for later?)
    # instantiate controller and call controller action
    def run(req, res)
      match_data = pattern.match(req.path)

      i = 0
      route_params = {}
      unless match_data.names.empty?
        while i < match_data.names.count
          route_params[match_data.names[i]] = match_data.captures[i]
          i += 1
        end
      end

      controller_class.new(req, res, route_params).invoke_action(action_name)
    end

  end

  class Router
    attr_reader :routes

    def initialize
      @routes = []
    end

    # simply adds a new route to the list of routes
    def add_route(pattern, method, controller_class, action_name)
      @routes << Route.new(pattern, method, controller_class, action_name)
    end

    # evaluate the proc in the context of the instance
    # for syntactic sugar :)
    def draw(&proc)
      proc.call(self)
    end

    # make each of these methods that
    # when called add route
    [:get, :post, :put, :delete].each do |http_method|
      define_method(http_method) do |pattern, controller_class, action_name|
        self.add_route(pattern, http_method, controller_class, action_name)
      end
    end

    # should return the route that matches this request
    def match(req)
      @routes.each do |route|
        return route if route.matches?(req)
      end
      return nil
    end

    # either throw 404 or call run on a matched route
    def run(req, res)
      if !!match(req)
        match(req).run(req,res)
      else
        res.status = 404
      end
    end
  end
end
