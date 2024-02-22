# Rails.application.routes.draw do
#   namespace :api, defaults: { format: :json }  do
#     namespace :v1 do
#       resources :keys, only: [:show]
#     end
#   end
# end

Rails.application.routes.draw do
  namespace :api, defaults: { format: :json }  do
    namespace :v1 do
      get '/show', to: 'keys#show'
    end
  end
end

