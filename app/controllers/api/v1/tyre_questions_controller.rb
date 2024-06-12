# app/controllers/api/v1/tyre_questions_controller.rb

class Api::V1::TyreQuestionsController < ApplicationController
  include ServiceTable
  include Constants
  include ServiceQustitionProcessing

  # def questions
  #   list_questions = []
  #   table = 'TyresFaq'

    # формирование основного блока вопрос ответ
    # rand(2..4).times do
    # =========================================================
    # закоменчено , для переделки (в принципе на небольших объемах работает)
    # ============================================================

    # 2.times do
    #   list_questions << question(table) unless question(table)[:question] == ""
    # end
    # # добавляем еще 1-4 вопроса по константам
    list_questions += questions_dop([CITIES, BRANDS, DIAMETERS, TOP_SIZE],
                                    [DIAMETERS_TRUCK, BRANDS_TRUCK, SIZE_TRUCK, DIAMETERS_WHEELS, BRANDS_WHEELS])
    #
    # result = format_question_full(list_questions)
    # puts result
    # render json: { list_questions: result }

    # =========================================================
    # ============================================================
  # rescue => e
  #   puts "Error occurred: #{e.message}"
  #   nil
  # end

  # def questions_track
  #   list_questions = []
  #   table = 'TrackTyresFaq'
  #   # формирование основного блока вопрос ответ
  #   2.times do
  #     list_questions << question(table) unless question(table)[:question] == ""
  #   end
  #   # добавляем еще 1-4 вопроса по константам
  #   list_questions += questions_dop([CITIES, DIAMETERS_TRUCK, BRANDS_TRUCK, SIZE_TRUCK],
  #                                   [BRANDS, DIAMETERS, TOP_SIZE, DIAMETERS_WHEELS, BRANDS_WHEELS])
  #
  #   result = format_question_full(list_questions)
  #   puts result
  #   render json: { list_questions: result }
  # end

  # def questions_diski
  #   list_questions = []
  #   table = 'DiskiFaq'
  #   # формирование основного блока вопрос ответ
  #   # rand(2..4).times do
  #   2.times do
  #     list_questions << question(table) unless question(table)[:question] == ""
  #   end
  #   # добавляем еще 1-4 вопроса по константам
  #   list_questions += questions_dop([CITIES, DIAMETERS_WHEELS, BRANDS_WHEELS],
  #                                   [BRANDS, DIAMETERS, TOP_SIZE, DIAMETERS_TRUCK, BRANDS_TRUCK, SIZE_TRUCK])
  #
  #   result = format_question_full(list_questions)
  #   puts result
  #   render json: { list_questions: result }
  # end



end