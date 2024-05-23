# app/controllers/api/v1/reviews_controller.rb

class Api::V1::ReviewsController < ApplicationController
  include ServiceReview

  def my_test
    result = ''

    result = generating_texts_and_writing_to_tables

    # result = additional_information_for_text_generation("зимние", "негативный")
    # result =  str_additional_information_for_text_generation
    puts "#{result.inspect} " # #{result.inspect}
    render json: { result: result }
  end

  def reviews

  end



  # =================================================================
  # Первоначальная загрузка данных
  # =================================================================
  def download_car_tire_size_info
    result = ''
    # TestTableCar2Brand.delete_all
    # TestTableCar2Model.delete_all
    # TestTableCar2Kit.delete_all
    # TestTableCar2KitDiskSize.delete_all
    # TestTableCar2KitTyreSize.delete_all
    i = 0
    file_path = 'lib/cars_db/test_table_car2_brand.csv'
    CSV.foreach(file_path, headers: true) do |row|
      begin
        brand = TestTableCar2Brand.find_or_initialize_by(id: row['id'])
        brand.update(name: row['name'])
        i += 1
      rescue CSV::MalformedCSVError
        next
      end
    end

    result += "в TestTableCar2Brand загружено записей: #{i}\n"
    i = 0

    file_path = 'lib/cars_db/test_table_car2_model.csv'
    CSV.foreach(file_path, headers: true) do |row|
      begin
        brand_id = row['brand'].to_i
        brand = TestTableCar2Brand.find_by(id: brand_id)
        if brand
          model = TestTableCar2Model.find_or_create_by(id: row['id'])
          model.update(brand: brand, name: row['name']) # использование объекта brand вместо строки
          i += 1
        end
      rescue CSV::MalformedCSVError
        next
      end
    end
    result += "в TestTableCar2Model загружено записей: #{i}\n"
    i = 0

    file_path = 'lib/cars_db/test_table_car2_kit.csv'
    CSV.foreach(file_path, headers: true) do |row|
      begin
        year = row['year'].to_i
        id_model = row['model'].to_i
        if year > 2004
          model = TestTableCar2Model.find_by(id: id_model)
          if model
            kit = TestTableCar2Kit.find_or_create_by(id: row['id'])
            kit.update(model: model, year: year,  # использование объекта model вместо числа
                       name: row['name'], pcd: row['pcd'], bolt_count: row['bolt_count'],
                       dia: row['dia'], bolt_size: row['bolt_size'])
            i += 1
          end
        end
      rescue CSV::MalformedCSVError
        next
      end
    end

    result += "в TestTableCar2Kit загружено записей: #{i}\n"
    i = 0

    file_path = 'lib/cars_db/test_table_car2_kit_disk_size.csv'
    CSV.foreach(file_path, headers: true) do |row|
      begin
        id_kit = row['kit'].to_i
        kit = TestTableCar2Kit.find_by(id: id_kit)
        if kit
          disk_size = TestTableCar2KitDiskSize.find_or_create_by(id: row['id'])
          disk_size.update(kit: kit, width: row['width'], diameter: row['diameter'],
                           et: row['et'], type_type: row['type'], axle: row['axle'],
                           axle_group: row['axle_group'])
          i += 1
        end
      rescue CSV::MalformedCSVError
        next
      end

    end

    result += "в TestTableCar2KitDiskSize загружено записей: #{i}\n"
    i = 0

    file_path = 'lib/cars_db/test_table_car2_kit_tyre_size.csv'
    CSV.foreach(file_path, headers: true) do |row|
      begin
        id_kit = row['kit'].to_i
        kit = TestTableCar2Kit.find_by(id: id_kit)
        if kit
          tyre_size = TestTableCar2KitTyreSize.find_or_create_by(id: row['id'])
          tyre_size.update(kit: kit, width: row['width'], height: row['height'],
                           diameter: row['diameter'], type_disabled: row['type'],
                           axle: row['axle'], axle_group: row['axle_group'])
          i += 1
        end
      rescue CSV::MalformedCSVError
        next
      end

    end

    result += "в TestTableCar2KitDiskSize загружено записей: #{i}\n"

    puts "#{result} "
    render plain: result

  end

  def fill_table_review
    result = generating_records_and_writing_to_table_review
    puts "#{result} "
    render plain: result
  end

  private
  def quire_params
    params.require(:quire).permit(:w, :h, :r, :season, :b, :m,:rating, :type_block)
  end

end