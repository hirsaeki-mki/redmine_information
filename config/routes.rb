
match '/information/:id', :to=> 'info#show', :via=>'get'
match '/information', :to=> 'info#index', :via=>'get'
