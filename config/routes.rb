require_relative 'routes/sidekiq'

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  root to: redirect('/api-docs')

  scope '/api/v1' do
    get '/cases', to: 'cases#index'
    get '/sync-cases', to: 'cases#sync'

    post '/users/find-or-create', to: 'users#create'
    patch '/tenancies/:tenancy_ref', to: 'tenancies#update'
    get '/tenancies/:tenancy_ref/pause', to: 'tenancies#pause'
    get '/tenancies/:tenancy_ref', to: 'tenancies#show'
    post '/tenancies/:tenancy_ref/action_diary', to: 'action_diary#create'
    post '/messages/send_sms', to: 'messages#send_sms'
    post '/messages/send_email', to: 'messages#send_email'
    get '/messages/get_templates', to: 'messages#get_templates'

    get '/documents/:id/download/', to: 'documents#download'
    get '/documents/', to: 'documents#index'
    patch '/documents/:id/review_failure', to: 'documents#review_failure'

    post '/messages/letters/send', to: 'letters#send_letter'
    post '/messages/letters', to: 'letters#create'
    get '/messages/letters/get_templates', to: 'letters#get_templates'

    get '/agreements/:tenancy_ref', to: 'agreements#index'
    post '/agreement/:tenancy_ref', to: 'agreements#create'
    post '/agreements/:agreement_id/cancel', to: 'agreements#cancel'

    post '/court_case/:tenancy_ref', to: 'court_cases#create'
  end
end
