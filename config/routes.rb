DNSDB::Application.routes.draw do

  resources :subnets, :only => [:index, :show, :new, :create, :destroy]
  resources :ips, :only => [:index, :show, :edit, :update]

  match 'ips' => 'ips#update', :via => :put

  resources :records
  resources :domains

end
