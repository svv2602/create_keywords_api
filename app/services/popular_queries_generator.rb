require_relative 'dictionaries/const_regex'

class PopularQueriesGenerator
  include TyreConstants

  PROMOTED_BRAND_NAMES = [
    "Hankook", "Michelin", "Continental", "Pirelli", "Nokian Tyres",
    "Goodyear", "Roadstone", "Nexen", "Toyo", "Yokohama",
    "Lassa", "Triangle", "Sailun", "Kumho", "Orium",
    "Grenlander", "Bridgestone", "Doublestar", "Habilead", "Kapsen",
    "Rydanz", "Firestone"
  ].freeze

  SEASONS = %w[letnie zimnie vsesezonie].freeze

  SHINY_WORDS_RU = %w[шины резина покрышки автошины].freeze
  SHINY_WORDS_UA = %w[шини гума покришки автошини].freeze

  def initialize(url, language = 'ru')
    @language = language.to_s.downcase == 'ua' ? 'ua' : 'ru'
    @url = url.to_s
    parse_url
  end

  POPULAR_RADIUSES = %w[13 14 15 16 17 18 19 20].freeze

  def generate(count = 50)
    has_full_size = @width && @height && @radius

    queries = []
    queries.concat(build_combinations)
    queries.concat(build_current_brand_queries) if @brand_slug && !has_full_size
    queries.concat(build_brand_variations)
    queries.concat(build_general_queries)
    queries.concat(build_season_variations) unless @season
    queries.concat(build_popular_size_queries) if @radius && !@width
    queries.concat(build_radius_queries) unless @radius

    # Исключить запросы с URL, совпадающим с входным
    normalized_input = @url.gsub(%r{/+}, '/').sub(%r{/*\z}, '/')
    queries.reject! { |q| q[:url] == normalized_input }

    # Убрать дубли по URL (оставить первый вариант текста)
    queries.uniq! { |q| q[:url] }

    total = [count, 20].max

    # Правило 70% бренда — только если нет полного размера в URL
    if @brand_slug && !has_full_size
      brand_re = /#{Regexp.escape(@brand_slug)}/i
      with_brand = queries.select { |q| q[:url] =~ brand_re }.shuffle
      without_brand = queries.reject { |q| q[:url] =~ brand_re }.shuffle

      brand_target = (total * 0.7).round
      other_target = total - brand_target

      result = with_brand.first(brand_target) + without_brand.first(other_target)
      if result.size < total
        remaining = (with_brand + without_brand) - result
        result.concat(remaining.first(total - result.size))
      end
      result.shuffle
    else
      queries.shuffle.first(total)
    end
  end

  private

  def parse_url
    parts = @url.split('/').reject(&:empty?)
    # Remove leading 'shiny' and optional 'ua'
    parts.delete('shiny')
    parts.delete('ua')

    @season = nil
    @brand_slug = nil
    @width = nil
    @height = nil
    @radius = nil
    @commercial = false

    parts.each do |part|
      case part
      when *SEASONS
        @season = part
      when /\Aw-(\d+)\z/
        @width = $1
      when /\Ah-(\d+)\z/
        @height = $1
      when /\Ar-(\d[\d.]*)c\z/i
        @radius = $1
        @commercial = true
      when /\Ar-(\d[\d.]*)\z/
        @radius = $1
      else
        # Any unrecognized segment is a brand slug
        @brand_slug = part
      end
    end
  end

  # --- Block 1: Combinations from current parameters (~10) ---
  def build_combinations
    templates = []

    rp = radius_url_part

    if @season && @brand_slug && @width && @height && @radius
      templates << { parts: [:season, :brand, :size], url: "/shiny/#{@season}/#{@brand_slug}/w-#{@width}/h-#{@height}/#{rp}/" }
    end
    if @season && @brand_slug && @radius
      templates << { parts: [:season, :brand, :radius], url: "/shiny/#{@season}/#{@brand_slug}/#{rp}/" }
    end
    if @season && @brand_slug
      templates << { parts: [:season, :brand], url: "/shiny/#{@season}/#{@brand_slug}/" }
    end
    if @season && @width && @height && @radius
      templates << { parts: [:season, :size], url: "/shiny/#{@season}/w-#{@width}/h-#{@height}/#{rp}/" }
    end
    if @season && @radius
      templates << { parts: [:season, :radius], url: "/shiny/#{@season}/#{rp}/" }
    end
    if @season
      templates << { parts: [:season], url: "/shiny/#{@season}/" }
    end
    if @brand_slug && @width && @height && @radius
      templates << { parts: [:brand, :size], url: "/shiny/#{@brand_slug}/w-#{@width}/h-#{@height}/#{rp}/" }
    end
    if @brand_slug && @radius
      templates << { parts: [:brand, :radius], url: "/shiny/#{@brand_slug}/#{rp}/" }
    end
    if @width && @height && @radius
      templates << { parts: [:size], url: "/shiny/w-#{@width}/h-#{@height}/#{rp}/" }
    end
    if @radius
      templates << { parts: [:radius], url: "/shiny/#{rp}/" }
    end

    # Normalize input URL for comparison
    normalized_input = @url.gsub(%r{/+}, '/').sub(%r{/*\z}, '/')

    templates.reject { |t| t[:url] == normalized_input }.map do |t|
      text = build_text_from_parts(t[:parts])
      { text: text, url: t[:url] }
    end
  end

  # --- Block 1b: Current brand queries (~70% от итога) ---
  def build_current_brand_queries
    queries = []

    seasons_to_use = @season ? [@season] : SEASONS

    # бренд + сезон
    seasons_to_use.each do |season|
      queries << {
        text: build_text_from_parts([:season, :brand], season_override: season),
        url: "/shiny/#{season}/#{@brand_slug}/"
      }
    end

    # бренд + сезон + радиус
    if @radius
      rp = radius_url_part
      seasons_to_use.each do |season|
        queries << {
          text: build_text_from_parts([:season, :brand, :radius], season_override: season),
          url: "/shiny/#{season}/#{@brand_slug}/#{rp}/"
        }
      end
      # бренд + радиус (без сезона)
      queries << {
        text: build_text_from_parts([:brand, :radius]),
        url: "/shiny/#{@brand_slug}/#{rp}/"
      }
    end

    # бренд + текущий размер с другими сезонами
    if @width && @height && @radius
      rp = radius_url_part
      (SEASONS - seasons_to_use).each do |season|
        queries << {
          text: build_text_from_parts([:season, :brand, :size], season_override: season),
          url: "/shiny/#{season}/#{@brand_slug}/w-#{@width}/h-#{@height}/#{rp}/"
        }
      end
    end

    # бренд + популярные размеры
    if @radius && !@width
      # Есть диаметр, но нет размера — только размеры текущего диаметра
      all_sizes = popular_sizes_for_radius
      selected_sizes = all_sizes.sample([all_sizes.size, rand(6..8)].min)

      selected_sizes.each do |size_str|
        w, h, parsed_r, size_c = parse_size_string(size_str)
        next unless w && h && parsed_r
        srp = radius_url_part(parsed_r, commercial: size_c)
        # Каждый размер — со случайным сезоном
        season = seasons_to_use.sample
        queries << {
          text: build_text_from_parts([:season, :brand, :size], season_override: season, size_override: [w, h, parsed_r, size_c]),
          url: "/shiny/#{season}/#{@brand_slug}/w-#{w}/h-#{h}/#{srp}/"
        }
        # Дополнительно: тот же размер с другим сезоном (~40%)
        if rand < 0.4
          other_season = (SEASONS - [season]).sample
          queries << {
            text: build_text_from_parts([:season, :brand, :size], season_override: other_season, size_override: [w, h, parsed_r, size_c]),
            url: "/shiny/#{other_season}/#{@brand_slug}/w-#{w}/h-#{h}/#{srp}/"
          }
        end
      end
    elsif !@radius
      # Нет диаметра — размеры из случайных диаметров
      radiuses_for_sizes = POPULAR_RADIUSES.sample(rand(4..6))

      radiuses_for_sizes.each do |r|
        sizes_hash = @commercial ? TIRE_POPULAR_SIZES_C : TIRE_POPULAR_SIZES
        all_sizes = sizes_hash[r.to_s.to_sym] || []
        all_sizes = all_sizes.reject { |s| s =~ /c\s*\z/i } unless @commercial
        selected_sizes = all_sizes.reject { |s|
          w, h, _rr = parse_size_string(s)
          w == @width && h == @height
        }.sample(rand(3..5))

        selected_sizes.each do |size_str|
          w, h, parsed_r, size_c = parse_size_string(size_str)
          next unless w && h && parsed_r
          srp = radius_url_part(parsed_r, commercial: size_c)
          season = seasons_to_use.sample
          queries << {
            text: build_text_from_parts([:season, :brand, :size], season_override: season, size_override: [w, h, parsed_r, size_c]),
            url: "/shiny/#{season}/#{@brand_slug}/w-#{w}/h-#{h}/#{srp}/"
          }
        end

        # бренд + сезон + диаметр
        rp = radius_url_part(r)
        season = seasons_to_use.sample
        queries << {
          text: build_text_from_parts([:season, :brand, :radius], season_override: season, radius_override: r),
          url: "/shiny/#{season}/#{@brand_slug}/#{rp}/"
        }
        queries << {
          text: build_text_from_parts([:brand, :radius], radius_override: r),
          url: "/shiny/#{@brand_slug}/#{rp}/"
        }
      end
    end

    # Исключить дубли с входным URL
    normalized_input = @url.gsub(%r{/+}, '/').sub(%r{/*\z}, '/')
    queries.reject { |q| q[:url] == normalized_input }
  end

  # --- Block 2: Other brands (~10-15) ---
  def build_brand_variations
    other_brands = promoted_brands.reject { |b| b[:slug] == @brand_slug }
    brand_count = @brand_slug ? rand(5..8) : rand(10..15)
    selected = other_brands.sample(brand_count)

    selected.flat_map do |brand|
      queries = []
      # Если сезон не задан в URL — назначаем случайный для каждого бренда
      brand_season = @season || SEASONS.sample

      # Query 1: brand + season + size/radius
      parts_for_query = [:season, :brand]
      url_parts = [brand_season, brand[:slug]]

      if @width && @height && @radius
        rp = radius_url_part
        parts_for_query << :size
        url_suffix = "w-#{@width}/h-#{@height}/#{rp}"
        link_url = "/shiny/#{url_parts.join('/')}/#{url_suffix}/"
        text = build_text_from_parts(parts_for_query, brand_name: brand[:name], brand_slug: brand[:slug], season_override: brand_season)
        queries << { text: text, url: link_url }
      elsif @radius
        rp = radius_url_part
        parts_for_query << :radius
        link_url = "/shiny/#{url_parts.join('/')}/#{rp}/"
        text = build_text_from_parts(parts_for_query, brand_name: brand[:name], brand_slug: brand[:slug], season_override: brand_season)
        queries << { text: text, url: link_url }
      else
        # Нет радиуса — сезон+бренд и дополнительно сезон+бренд+случайный_радиус
        link_url = "/shiny/#{url_parts.join('/')}/"
        text = build_text_from_parts(parts_for_query, brand_name: brand[:name], brand_slug: brand[:slug], season_override: brand_season)
        queries << { text: text, url: link_url }

        if rand < 0.6
          r = POPULAR_RADIUSES.sample
          rp = radius_url_part(r)
          text_r = build_text_from_parts([:season, :brand, :radius], brand_name: brand[:name], brand_slug: brand[:slug], season_override: brand_season, radius_override: r)
          queries << { text: text_r, url: "/shiny/#{url_parts.join('/')}/#{rp}/" }
        end
      end

      # Второй запрос (~50%): brand + только radius
      if rand < 0.5 && @radius && @width && @height
        rp = radius_url_part
        alt_parts = [:brand]
        use_season = rand < 0.5
        alt_season = use_season ? (@season || SEASONS.sample) : nil
        alt_parts.unshift(:season) if use_season
        alt_parts << :radius
        alt_url_parts = []
        alt_url_parts << alt_season if use_season
        alt_url_parts << brand[:slug]
        alt_link = "/shiny/#{alt_url_parts.join('/')}/#{rp}/"

        text2 = build_text_from_parts(alt_parts, brand_name: brand[:name], brand_slug: brand[:slug], season_override: alt_season)
        queries << { text: text2, url: alt_link }
      end

      queries
    end
  end

  # --- Block 3: General queries without brand (~3-5) ---
  def build_general_queries
    queries = []
    rp = radius_url_part

    if @season && @width && @height && @radius
      queries << build_query([:season, :size], "/shiny/#{@season}/w-#{@width}/h-#{@height}/#{rp}/")
    end
    if @season && @radius
      queries << build_query([:season, :radius], "/shiny/#{@season}/#{rp}/")
    end
    if @width && @height && @radius
      queries << build_query([:shiny_word, :size], "/shiny/w-#{@width}/h-#{@height}/#{rp}/")
    end
    if @radius
      queries << build_query([:shiny_word, :radius], "/shiny/#{rp}/")
    end
    if @season
      queries << build_query([:season], "/shiny/#{@season}/")
    end

    queries.compact.uniq { |q| q[:url] }
  end

  # --- Block 4: Season variations when no season in URL (~6-9) ---
  def build_season_variations
    queries = []
    rp = radius_url_part

    SEASONS.each do |season|
      if @width && @height && @radius
        queries << build_query([:season, :size], "/shiny/#{season}/w-#{@width}/h-#{@height}/#{rp}/", season_override: season)
      end
      if @radius
        queries << build_query([:season, :radius], "/shiny/#{season}/#{rp}/", season_override: season)
      end
      queries << build_query([:season], "/shiny/#{season}/", season_override: season)
    end

    queries.compact
  end

  # --- Block 5: Popular sizes for radius-only URLs (~8-12) ---
  def build_popular_size_queries
    sizes = popular_sizes_for_radius
    return [] if sizes.empty?

    selected = sizes.sample([sizes.size, rand(8..12)].min)

    selected.flat_map do |size_str|
      w, h, r, size_c = parse_size_string(size_str)
      next unless w && h && r

      queries = []
      season = @season || SEASONS.sample
      srp = radius_url_part(r, commercial: size_c)
      url = "/shiny/#{season}/w-#{w}/h-#{h}/#{srp}/"

      if @brand_slug
        # Есть бренд — чаще генерируем с текущим брендом
        if rand < 0.7
          brand_url = "/shiny/#{season}/#{@brand_slug}/w-#{w}/h-#{h}/#{srp}/"
          queries << {
            text: build_text_from_parts([:season, :brand, :size], season_override: season, size_override: [w, h, r, size_c]),
            url: brand_url
          }
        else
          # Без бренда
          queries << {
            text: build_text_from_parts([:season, :size], season_override: season, size_override: [w, h, r, size_c]),
            url: url
          }
        end
      else
        # Нет бренда — сезон + размер, иногда со случайным брендом
        queries << {
          text: build_text_from_parts([:season, :size], season_override: season, size_override: [w, h, r, size_c]),
          url: url
        }
        if rand < 0.4
          brand = promoted_brands.sample
          if brand
            brand_url = "/shiny/#{season}/#{brand[:slug]}/w-#{w}/h-#{h}/#{srp}/"
            queries << {
              text: build_text_from_parts([:season, :brand, :size], brand_name: brand[:name], brand_slug: brand[:slug], season_override: season, size_override: [w, h, r, size_c]),
              url: brand_url
            }
          end
        end
      end

      queries
    end.compact
  end

  # --- Block 6: Radius variations when no radius in URL (~8-12) ---
  def build_radius_queries
    queries = []
    selected_radiuses = POPULAR_RADIUSES.sample(rand(6..8))

    selected_radiuses.each do |r|
      season = @season || SEASONS.sample
      rp = radius_url_part(r)

      # бренд + сезон + радиус
      if @brand_slug
        queries << {
          text: build_text_from_parts([:season, :brand, :radius], season_override: season, radius_override: r),
          url: "/shiny/#{season}/#{@brand_slug}/#{rp}/"
        }
      end

      # сезон + радиус (без бренда)
      if rand < 0.5
        queries << {
          text: build_text_from_parts([:season, :radius], season_override: season, radius_override: r),
          url: "/shiny/#{season}/#{rp}/"
        }
      end

      # бренд + радиус (без сезона) — изредка
      if @brand_slug && rand < 0.3
        queries << {
          text: build_text_from_parts([:brand, :radius], radius_override: r),
          url: "/shiny/#{@brand_slug}/#{rp}/"
        }
      end
    end

    queries
  end

  def popular_sizes_for_radius
    key = @radius.to_s.to_sym
    if @commercial
      TIRE_POPULAR_SIZES_C[key] || []
    else
      sizes = TIRE_POPULAR_SIZES[key] || []
      sizes.reject { |s| s =~ /c\s*\z/i }
    end
  end

  def parse_size_string(size_str)
    # "175/65 R14" or "205/65 R16C" -> [width, height, radius, commercial]
    if size_str =~ /(\d+)\/(\d+)\s*R?(\d+)(c?)\s*\z/i
      [$1, $2, $3, !$4.empty?]
    end
  end

  def radius_url_part(r = nil, commercial: nil)
    r ||= @radius
    c = commercial.nil? ? @commercial : commercial
    c ? "r-#{r}c" : "r-#{r}"
  end

  # --- Text formatting helpers ---

  def build_query(parts, url, season_override: nil)
    { text: build_text_from_parts(parts, season_override: season_override), url: url }
  end

  def build_text_from_parts(parts, brand_name: nil, brand_slug: nil, season_override: nil, size_override: nil, radius_override: nil)
    effective_season = season_override || @season
    effective_radius = radius_override || @radius
    has_season_part = parts.include?(:season)

    components = parts.map do |part|
      case part
      when :season
        format_season_text(effective_season)
      when :brand
        format_brand_text(brand_name || current_brand_name, brand_slug || @brand_slug)
      when :size
        format_size_text(size_override)
      when :radius
        format_radius_text(effective_radius)
      when :shiny_word
        shiny_words.sample
      end
    end.compact

    # Если в запросе нет сезонной фразы (которая уже содержит «шины»/«резина»)
    # и нет явного :shiny_word, добавляем слово «шины»/«резина» с вероятностью ~50%
    if !has_season_part && !parts.include?(:shiny_word) && rand < 0.5
      components << shiny_words.sample
    end

    components.shuffle.join(' ')
  end

  def format_season_text(season = nil)
    season ||= @season
    return nil unless season
    variants = season_text_variants[season]
    variants&.sample
  end

  def format_size_text(override = nil)
    if override
      c = override[3]
      size_name(override[0], override[1], override[2], c)
    else
      return nil unless @width && @height && @radius
      size_name(@width, @height, @radius, @commercial)
    end
  end

  def format_radius_text(radius = nil)
    radius ||= @radius
    return nil unless radius
    c_suffix = @commercial ? 'C' : ''
    case rand(1..4)
    when 1 then "R#{radius}#{c_suffix}"
    when 2 then "на #{radius}#{c_suffix}"
    when 3 then "р#{radius}#{c_suffix}"
    when 4 then "r#{radius}#{c_suffix}"
    end
  end

  def format_brand_text(name, slug)
    return nil unless name && slug
    if rand < 0.3
      # Cyrillic via translit exceptions
      translit = translit_exceptions[slug.to_s.downcase]
      return translit if translit
    end
    # Latin with random case
    case rand(1..3)
    when 1 then name
    when 2 then name.downcase
    when 3 then name.upcase
    end
  end

  def current_brand_name
    return nil unless @brand_slug
    brand = promoted_brands.find { |b| b[:slug] == @brand_slug }
    brand ? brand[:name] : @brand_slug.capitalize
  end

  # Size formatting (matching keys_controller.rb size_name approach)
  def size_name(ww, hh, rr, commercial = false)
    c = commercial ? 'C' : ''
    case rand(1..120)
    when 1..5   then "#{ww} #{hh}R#{rr}#{c}"
    when 6..10  then "#{ww}/#{hh} R#{rr}#{c}"
    when 11..15 then "#{ww} #{hh} #{rr}#{c}"
    when 16..20 then "#{ww}/#{hh} R#{rr}#{c}"
    when 21..25 then "#{ww}/#{hh} #{rr}#{c}"
    when 26..30 then "#{ww}/#{hh} R#{rr}#{c}"
    when 31..40 then "#{ww} #{hh} R#{rr}#{c}"
    when 41..45 then "#{ww}х#{hh} #{rr}#{c}"
    when 46..50 then "#{ww}/#{hh}/#{rr}#{c}"
    when 51..55 then "#{ww}х#{hh} Р#{rr}#{c}"
    when 56..60 then "#{ww}/#{hh} р#{rr}#{c}"
    when 61..65 then "#{ww}/#{hh} на #{rr}#{c}"
    when 66..70 then "#{ww}/#{hh} на R#{rr}#{c}"
    when 71..80 then "#{ww}/#{hh}R#{rr}#{c}"
    when 81..85 then "R#{rr}#{c} на #{ww} #{hh}"
    when 86..90 then "р#{rr}#{c} на #{ww} #{hh}"
    when 91..95 then "#{ww} #{hh} #{rr}#{c}"
    when 96..100 then "#{ww}/#{hh}R#{rr}#{c}"
    else "#{ww} #{hh} R#{rr}#{c}"
    end
  end

  # --- Language-dependent lookups ---

  def season_text_variants
    @language == 'ua' ? SEASON_TEXT_VARIANTS_UA : SEASON_TEXT_VARIANTS_RU
  end

  def translit_exceptions
    @language == 'ua' ? TRANSLIT_EXCEPTIONS_UA : TRANSLIT_EXCEPTIONS_RU
  end

  def shiny_words
    @language == 'ua' ? SHINY_WORDS_UA : SHINY_WORDS_RU
  end

  # --- Promoted brands from tyre_models.json (class-level cache) ---

  def promoted_brands
    self.class.promoted_brands
  end

  def self.promoted_brands
    @promoted_brands ||= load_promoted_brands
  end

  def self.load_promoted_brands
    models = JSON.parse(File.read(Rails.root.join('lib', 'tyre_models.json')))
    # Build name -> slug mapping from URLs
    brand_slug_map = {}
    models.each do |m|
      slug = m['url'].to_s.split('/')[1]
      brand_slug_map[m['brand']] ||= slug
    end

    PROMOTED_BRAND_NAMES.filter_map do |name|
      slug = brand_slug_map[name]
      next unless slug
      { name: name, slug: slug }
    end
  end

  def self.reset_brands_cache!
    @promoted_brands = nil
  end
end
