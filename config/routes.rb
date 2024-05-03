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
      get '/mytest', to: 'seo_texts#mytest'

    end

  end

  get '/download_database', to: 'exports#download_database'
  get '/export_text', to: 'exports#export_text'
  get '/export_sentence', to: 'exports#export_sentence'
  get '/count_records', to: 'exports#count_records'
  get '/readme', to: 'exports#readme'
  get '/clear_tables_texts', to: 'exports#clear_tables_texts'
  get '/control_records', to: 'exports#control_records'
  get '/count_records_check_title', to: 'exports#count_records_check_title'
  get '/export_xlsx', to: 'exports#export_xlsx'
  get '/process_files_ua', to: 'exports#process_files_ua'
  get '/control_question', to: 'exports#control_question'
  get '/export_questions_to_xlsx', to: 'exports#export_questions_to_xlsx'
  get '/add_new_brand_entries', to: 'exports#add_new_brand_entries'
  get '/replace_text_in_seo_content_text_sentence', to: 'exports#replace_text_in_seo_content_text_sentence'
  get '/replace_size_in_seo_content_text_sentence_r22', to: 'exports#replace_size_in_seo_content_text_sentence_r22'
  get '/replace_name_brand_total', to: 'exports#replace_name_brand_total'


end

