require_relative 'routes/sidekiq'

Rails.application.routes.draw do
  scope '/api/v1' do
    get '/my-cases', to: 'my_cases#index'
    get '/sync-cases', to: 'my_cases#sync'
    post '/users/find-or-create', to: 'users#create'
    patch '/tenancies/:tenancy_ref', to: 'tenancies#update'
    get '/tenancies/:tenancy_ref/pause', to: 'tenancies#pause'
    post '/tenancies/:tenancy_ref/action_diary', to: 'action_diary#create'
    post '/messages/send_sms', to: 'messages#send_sms'
    post '/messages/send_email', to: 'messages#send_email'
    get '/messages/get_templates', to: 'messages#get_templates'
    get '/pdf/get_templates', to: 'pdf#get_templates'
    post '/pdf/send_letter', to: 'pdf#send_letter'

    get '/letters/:uuid', to: 'letters#download'
  end
end
