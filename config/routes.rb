ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'home'

  map.resources :users,
    :member => { :suspend => :put, :unsuspend => :put, :purge => :delete},
    :collection => { :all => :get, :pending => :get }
  map.resource :session

  map.login '/login', :controller => 'sessions', :action => 'new', :conditions => { :method => :get }
  map.logout '/logout', :controller => 'sessions', :action => 'destroy', :conditions => { :method => :get }
  map.register '/register', :controller => 'users', :action => 'new', :conditions => { :method => :get }
  map.activate '/activate', :controller => 'users', :action => 'activate', :conditions => { :method => :get }
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :conditions => { :method => :get }

  map.user_requests '/user_requests', :controller => 'user_requests', :action => 'index', :conditions => { :method => :get }
  map.approve_user_request '/user_requests/:id/approve', :controller => 'user_requests', :action => 'approve', :conditions => { :method => :put }
  map.reject_user_request '/user_requests/:id/reject', :controller => 'user_requests', :action => 'reject', :conditions => { :method => :put }
  map.revoke_user_request '/user_requests/:id/revoke', :controller => 'user_requests', :action => 'revoke', :conditions => { :method => :put }

  map.connect '/documents/:id/download/:style.:format', :controller => 'documents', :action => 'download', :conditions => { :method => :get }
  map.resources :documents

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  #map.connect ':controller/:action/:id'
  #map.connect ':controller/:action/:id.:format'

end
