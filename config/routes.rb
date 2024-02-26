# config/routes.rb
Rails.application.routes.draw do
  namespace :api, defaults: { format: :json }  do

    namespace :v1 do
      get '/show', to: 'keys#show'
      get '/generate_completion', to: 'openai#generate_completion'
    end

  end
end

