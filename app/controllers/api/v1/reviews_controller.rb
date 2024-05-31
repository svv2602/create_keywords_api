# app/controllers/api/v1/reviews_controller.rb

class Api::V1::ReviewsController < ApplicationController
  include ServiceReview
  include ServiceReviewOut

  def my_test
    result = ''

    puts "#{result.inspect} " # #{result.inspect}
    render json: { result: result }
  end

  def create_review_templates
    # Генерация отзывов
    # /api/v1/create_review_templates?min=25000&max=30000
    # /api/v1/create_review_templates?min=30000&max=35000
    # /api/v1/create_review_templates?min=35000&max=40000
    # /api/v1/create_review_templates?min=45000&max=50000
    # /api/v1/create_review_templates?min=40000&max=45000

    result = select_texts_for_generating_reviews
    result = "Добавлено записей: #{result} "
    render json: { result: result }
  end

  def reviews
    tyres = params[:tyres]
    result = collect_the_answer(tyres)
    render json: { result: result.inspect }, status: :ok
  end

  def reviews_for_model
    tyres = params
    new_hash = makes_hash_for_collect_the_answer(tyres)
    result = collect_the_answer(new_hash[:tyres], new_hash[:grade])
    render json: { result: result.inspect }, status: :ok
  end

  # =================================================================
  # Первоначальная загрузка данных
  # =================================================================

  def add_brand
    result = ''
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
    result

  end

  def add_model
    result = ''

    arr_models_id = [1, 4, 10, 11, 12, 14, 15, 21, 23, 26, 28, 29, 31, 82, 84, 85, 87, 88, 90, 91, 95, 96, 97, 98, 99, 100, 101, 104, 105, 106, 107, 108,
                     111, 112, 113, 114, 115, 116, 119, 120, 121, 189, 191, 192, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 210,
                     211, 212, 214, 215, 216, 219, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 244, 247, 248, 249,
                     250, 421, 429, 430, 431, 432, 433, 434, 435, 436, 437, 438, 439, 447, 448, 449, 471, 473, 484, 490, 494, 498, 500, 503, 504, 507,
                     511, 513, 514, 536, 537, 545, 549, 554, 598, 599, 600, 601, 602, 603, 616, 638, 663, 665, 670, 671, 672, 673, 674, 675, 676, 677,
                     678, 679, 680, 682, 683, 684, 685, 686, 687, 688, 697, 698, 708, 709, 711, 713, 714, 715, 716, 717, 718, 719, 720, 721, 844, 847,
                     848, 853, 855, 863, 1147, 1148, 1149, 1150, 1156, 1161, 1162, 1167, 1168, 1170, 1178, 1181, 1182, 1188, 1189, 1192, 1194, 1210,
                     1221, 1223, 1229, 1232, 1233, 1234, 1239, 1240, 1242, 1245, 1246, 1247, 1250, 1259, 1261, 1266, 1267, 1287, 1296, 1514, 1516,
                     1533, 1543, 1546, 1549, 1568, 1577, 1581, 1594, 1632, 1642, 1645, 1650, 1654, 1656, 1658, 1661, 1662, 1663, 1664, 1667, 1668,
                     1672, 1674, 1681, 1682, 1683, 1688, 1696, 1699, 1700, 1701, 1706, 1710, 1714, 1715, 1716, 1723, 1724, 1727, 1728, 1730, 1732,
                     1735, 1828, 1830, 1831, 1832, 1835, 1836, 1838, 1884, 1885, 1886, 1890, 1892, 1906, 1907, 1911, 1927, 1932, 1938, 2017, 2020,
                     2021, 2022, 2023, 2024, 2025, 2026, 2030, 2031, 2032, 2033, 2036, 2037, 2041, 2048, 2051, 2181, 2182, 2184, 2185, 2208, 2209,
                     2210, 2211, 2212, 2236, 2238, 2239, 2248, 2276, 2278, 2279, 2283, 2284, 2285, 2286, 2288, 2289, 2290, 2297, 2300, 2305, 2306,
                     2307, 2309, 2311, 2312, 2313, 2317, 2318, 2320, 2321, 2322, 2324, 2325, 2326, 2328, 2329, 2333, 2336, 2340, 2341, 2342, 2343,
                     2345, 2346, 2347, 2348, 2349, 2355, 2357, 2358, 2359, 2369, 2371, 2373, 2374, 2380, 2383, 2385, 2386, 2387, 2435, 2436, 2438,
                     2440, 2441, 2442, 2443, 2444, 2453, 2460, 2477, 2492, 2498, 2503, 2504, 2505, 2509, 2511, 2512, 2513, 2530, 2531, 2532, 2533,
                     2538, 2574, 2575, 2577, 2593, 2615, 2624, 2633, 2638, 2639, 2640, 2666, 2679, 2680, 2681, 2682, 2687, 2690, 2698, 2705, 2710,
                     2724, 2725, 2751, 2762, 2769, 2770, 2775, 2785, 2786, 2791, 2820, 2821, 2827, 2836, 2839, 2853, 2912, 2918, 2921, 2922, 2923,
                     2924, 2989, 2990, 2991, 2994, 2996, 2998, 2999, 3001, 3003, 3006, 3010, 3015, 3016, 3018, 3096, 3104, 3106, 3111, 3114, 3118,
                     3119, 3121, 3122, 3123, 3124, 3125, 3126, 3127, 3128, 3129, 3130, 3131, 3132, 3179, 3180, 3188, 3191, 3192, 3216, 3224, 3225,
                     3265, 3269, 3271, 3293, 3295, 3296, 3297, 3298, 3352, 3353, 3354, 3355, 3356, 3357, 3371, 3372, 3379, 3383, 3398, 3437, 3448,
                     3460, 3463, 3467, 3503, 3504, 3505, 3506, 3526, 3528, 3551, 3557, 3559, 3575, 3579, 3580, 3610, 3615, 3624, 3636, 3642, 3643,
                     3646, 3659, 3660, 3661, 3666, 3677, 3680, 3682, 3687, 3704, 3707, 3709, 3710, 3713, 3735, 3736, 3739, 3740, 3743, 3745, 3746,
                     3747, 3748, 3749, 3750, 3753, 3754, 3889, 3890, 3891, 3910, 3914, 3915, 3916, 4004, 4010, 4012, 4013, 4014, 4023, 4024, 4063,
                     4079, 4090, 4308, 4349, 4416, 4449, 4760, 4761, 4769, 4770, 4771, 4826, 4827, 4837, 4844, 4869, 4908, 4924, 4925, 4926, 4927,
                     4937, 4938, 4951, 4962, 5013, 5014, 5016, 5018, 5019, 5021, 5023, 5027, 5028, 5035, 5050, 5051, 5052, 5060, 5061, 5062, 5065,
                     5097, 5098, 5099, 5119, 5120, 5121, 5130, 5165, 5368, 5369, 5372, 5379, 5380, 5381, 5403, 5461, 5462, 5463, 5499, 5502, 5506,
                     5522, 5530, 5616, 5618, 5619, 5620, 5625, 5627, 5651, 5661, 5679, 5680, 5681, 5682, 5697]
    i = 0

    file_path = 'lib/cars_db/test_table_car2_model.csv'
    CSV.foreach(file_path, headers: true) do |row|
      begin
        brand_id = row['brand'].to_i
        model_id = row['id'].to_i
        brand = TestTableCar2Brand.find_by(id: brand_id)
        if brand && arr_models_id.include?(model_id)
          model = TestTableCar2Model.find_or_create_by(id: row['id'])
          model.update(brand: brand, name: row['name']) # использование объекта brand вместо строки
          i += 1
        end
      rescue CSV::MalformedCSVError
        next
      end
    end
    result += "в TestTableCar2Model загружено записей: #{i}\n"
    result

  end

  def add_kit
    result = ''
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
            if kit.update(model: model, year: year,
                          name: row['name'], pcd: row['pcd'], bolt_count: row['bolt_count'],
                          dia: row['dia'], bolt_size: row['bolt_size'])
              # Update was successful
              puts "Successfully updated kit with id #{kit.id}"
              i += 1
            else
              # Update failed
              puts "Failed to update kit with id #{kit.id}. Errors: #{kit.errors.full_messages.join(", ")}"
            end
          end
        end
      rescue CSV::MalformedCSVError
        next
      end
    end

    result += "в TestTableCar2Kit загружено записей: #{i}\n"
    result

  end

  def add_kit_disk
    result = ''
    i = 0
    j = 0

    file_path = 'lib/cars_db/test_table_car2_kit_disk_size.csv'
    CSV.foreach(file_path, headers: true) do |row|
      begin
        id_kit = row['kit'].to_i
        kit = TestTableCar2Kit.find_by(id: id_kit)
        if kit

          disk_size = TestTableCar2KitDiskSize.find_or_create_by(id: row['id'])
          puts "disk_size = #{disk_size.inspect}"
          disk_size.update(kit: kit, width: row['width'], diameter: row['diameter'],
                           et: row['et'], type_type: row['type'], axle: row['axle'],
                           axle_group: row['axle_group'])
          i += 1
        end
      rescue CSV::MalformedCSVError
        next
      end
      # j +=1
      # break if j == 20
    end

    result += "в TestTableCar2KitDiskSize загружено записей: #{i}\n"
    result

  end

  def add_kit_tyre
    result = ''
    i = 0
    j = 0
    file_path = 'lib/cars_db/test_table_car2_kit_tyre_size.csv'
    CSV.foreach(file_path, headers: true) do |row|
      begin
        id_kit = row['kit'].to_i
        kit = TestTableCar2Kit.find_by(id: id_kit)
        if kit
          puts "kit = #{kit.inspect}"
          tyre_size = TestTableCar2KitTyreSize.find_or_create_by(id: row['id'])
          puts "tyre_size = #{tyre_size.inspect}"
          tyre_size.update(kit: kit, width: row['width'], height: row['height'],
                           diameter: row['diameter'], type_disabled: row['type'],
                           axle: row['axle'], axle_group: row['axle_group'])
          puts "tyre_size2 = #{tyre_size.inspect}"
          i += 1
        end
      rescue CSV::MalformedCSVError
        next
      end

      # j +=1
      # break if j == 20

    end

    result += "в TestTableCar2KitDiskSize загружено записей: #{i}\n"
    result
  end

  def download_car_tire_size_info
    result = ''
    # TestTableCar2Brand.delete_all
    # TestTableCar2Model.delete_all
    # TestTableCar2Kit.delete_all
    # TestTableCar2KitDiskSize.delete_all
    # TestTableCar2KitTyreSize.delete_all

    result += add_brand
    result += add_model
    result += add_kit
    result += add_kit_disk
    result += add_kit_tyre

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
    params.require(:quire).permit(:w, :h, :r, :season, :b, :m, :rating, :type_block)
  end

end