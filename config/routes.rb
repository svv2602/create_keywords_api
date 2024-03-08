# config/routes.rb
Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do

    namespace :v1 do
      get '/show', to: 'keys#show'
      get '/generate_completion', to: 'openai#generate_completion'
      get '/questions', to: 'tyre_questions#questions'
      get '/questions_track', to: 'tyre_questions#questions_track'
      get '/questions_diski', to: 'tyre_questions#questions_diski'
      get '/text_line', to: 'text_error#text_line'

    end

  end
end

