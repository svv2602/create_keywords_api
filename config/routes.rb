# config/routes.rb
Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do

    namespace :v1 do
      get '/show', to: 'keys#show'
      get '/generate_completion', to: 'openai#generate_completion'
      get '/generate_completion_season', to: 'openai#generate_completion_season'

      get '/questions', to: 'tyre_questions#questions'
      get '/questions_track', to: 'tyre_questions#questions_track'
      get '/questions_diski', to: 'tyre_questions#questions_diski'
      get '/text_line', to: 'text_error#text_line'
      get '/seo_text', to: 'seo_texts#seo_text'
      get '/json_write_for_read', to: 'seo_texts#json_write_for_read'
      get '/total_arr_to_table', to: 'seo_texts#total_arr_to_table'
      get '/total_arr_to_table_sentence', to: 'seo_texts#total_arr_to_table_sentence'
      get '/total_generate_seo_text', to: 'seo_texts#total_generate_seo_text'

    end

  end
  get '/export_text', to: 'exports#export_text'
  get '/export_sentence', to: 'exports#export_sentence'
  get '/count_records', to: 'exports#count_records'

end

