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

  def generate(count = 30)
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

    parts.each do |part|
      case part
      when *SEASONS
        @season = part
      when /\Aw-(\d+)\z/
        @width = $1
      when /\Ah-(\d+)\z/
        @height = $1
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

    if @season && @brand_slug && @width && @height && @radius
      templates << { parts: [:season, :brand, :size], url: "/shiny/#{@season}/#{@brand_slug}/w-#{@width}/h-#{@height}/r-#{@radius}/" }
    end
    if @season && @brand_slug && @radius
      templates << { parts: [:season, :brand, :radius], url: "/shiny/#{@season}/#{@brand_slug}/r-#{@radius}/" }
    end
    if @season && @brand_slug
      templates << { parts: [:season, :brand], url: "/shiny/#{@season}/#{@brand_slug}/" }
    end
    if @season && @width && @height && @radius
      templates << { parts: [:season, :size], url: "/shiny/#{@season}/w-#{@width}/h-#{@height}/r-#{@radius}/" }
    end
    if @season && @radius
      templates << { parts: [:season, :radius], url: "/shiny/#{@season}/r-#{@radius}/" }
    end
    if @season
      templates << { parts: [:season], url: "/shiny/#{@season}/" }
    end
    if @brand_slug && @width && @height && @radius
      templates << { parts: [:brand, :size], url: "/shiny/#{@brand_slug}/w-#{@width}/h-#{@height}/r-#{@radius}/" }
    end
    if @brand_slug && @radius
      templates << { parts: [:brand, :radius], url: "/shiny/#{@brand_slug}/r-#{@radius}/" }
    end
    if @width && @height && @radius
      templates << { parts: [:size], url: "/shiny/w-#{@width}/h-#{@height}/r-#{@radius}/" }
    end
    if @radius
      templates << { parts: [:radius], url: "/shiny/r-#{@radius}/" }
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
      seasons_to_use.each do |season|
        queries << {
          text: build_text_from_parts([:season, :brand, :radius], season_override: season),
          url: "/shiny/#{season}/#{@brand_slug}/r-#{@radius}/"
        }
      end
      # бренд + радиус (без сезона)
      queries << {
        text: build_text_from_parts([:brand, :radius]),
        url: "/shiny/#{@brand_slug}/r-#{@radius}/"
      }
    end

    # бренд + текущий размер с другими сезонами
    if @width && @height && @radius
      (SEASONS - seasons_to_use).each do |season|
        queries << {
          text: build_text_from_parts([:season, :brand, :size], season_override: season),
          url: "/shiny/#{season}/#{@brand_slug}/w-#{@width}/h-#{@height}/r-#{@radius}/"
        }
      end
    end

    # бренд + популярные размеры из TIRE_POPULAR_SIZES
    radiuses_for_sizes = if @radius
                           # текущий диаметр + 2-3 других
                           ([@radius] + POPULAR_RADIUSES.reject { |r| r == @radius }.sample(rand(2..3))).uniq
                         else
                           POPULAR_RADIUSES.sample(rand(4..6))
                         end

    radiuses_for_sizes.each do |r|
      all_sizes = TIRE_POPULAR_SIZES[r.to_s.to_sym] || []
      # Исключить текущий размер, если он совпадает
      selected_sizes = all_sizes.reject { |s|
        w, h, _rr = parse_size_string(s)
        w == @width && h == @height
      }.sample(rand(3..5))

      selected_sizes.each do |size_str|
        w, h, parsed_r = parse_size_string(size_str)
        next unless w && h && parsed_r
        season = seasons_to_use.sample
        queries << {
          text: build_text_from_parts([:season, :brand, :size], season_override: season, size_override: [w, h, parsed_r]),
          url: "/shiny/#{season}/#{@brand_slug}/w-#{w}/h-#{h}/r-#{parsed_r}/"
        }
      end

      # бренд + сезон + диаметр
      unless @radius
        season = seasons_to_use.sample
        queries << {
          text: build_text_from_parts([:season, :brand, :radius], season_override: season, radius_override: r),
          url: "/shiny/#{season}/#{@brand_slug}/r-#{r}/"
        }
        queries << {
          text: build_text_from_parts([:brand, :radius], radius_override: r),
          url: "/shiny/#{@brand_slug}/r-#{r}/"
        }
      end
    end

    # бренд + другие диаметры (когда в URL есть конкретный радиус)
    if @radius
      other_radiuses = POPULAR_RADIUSES.reject { |r| r == @radius }.sample(rand(4..6))
      other_radiuses.each do |r|
        season = seasons_to_use.sample
        queries << {
          text: build_text_from_parts([:season, :brand, :radius], season_override: season, radius_override: r),
          url: "/shiny/#{season}/#{@brand_slug}/r-#{r}/"
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
        parts_for_query << :size
        url_suffix = "w-#{@width}/h-#{@height}/r-#{@radius}"
        link_url = "/shiny/#{url_parts.join('/')}/#{url_suffix}/"
        text = build_text_from_parts(parts_for_query, brand_name: brand[:name], brand_slug: brand[:slug], season_override: brand_season)
        queries << { text: text, url: link_url }
      elsif @radius
        parts_for_query << :radius
        link_url = "/shiny/#{url_parts.join('/')}/r-#{@radius}/"
        text = build_text_from_parts(parts_for_query, brand_name: brand[:name], brand_slug: brand[:slug], season_override: brand_season)
        queries << { text: text, url: link_url }
      else
        # Нет радиуса — сезон+бренд и дополнительно сезон+бренд+случайный_радиус
        link_url = "/shiny/#{url_parts.join('/')}/"
        text = build_text_from_parts(parts_for_query, brand_name: brand[:name], brand_slug: brand[:slug], season_override: brand_season)
        queries << { text: text, url: link_url }

        if rand < 0.6
          r = POPULAR_RADIUSES.sample
          text_r = build_text_from_parts([:season, :brand, :radius], brand_name: brand[:name], brand_slug: brand[:slug], season_override: brand_season, radius_override: r)
          queries << { text: text_r, url: "/shiny/#{url_parts.join('/')}/r-#{r}/" }
        end
      end

      # Второй запрос (~50%): brand + только radius
      if rand < 0.5 && @radius && @width && @height
        alt_parts = [:brand]
        use_season = rand < 0.5
        alt_season = use_season ? (@season || SEASONS.sample) : nil
        alt_parts.unshift(:season) if use_season
        alt_parts << :radius
        alt_url_parts = []
        alt_url_parts << alt_season if use_season
        alt_url_parts << brand[:slug]
        alt_link = "/shiny/#{alt_url_parts.join('/')}/r-#{@radius}/"

        text2 = build_text_from_parts(alt_parts, brand_name: brand[:name], brand_slug: brand[:slug], season_override: alt_season)
        queries << { text: text2, url: alt_link }
      end

      queries
    end
  end

  # --- Block 3: General queries without brand (~3-5) ---
  def build_general_queries
    queries = []

    if @season && @width && @height && @radius
      queries << build_query([:season, :size], "/shiny/#{@season}/w-#{@width}/h-#{@height}/r-#{@radius}/")
    end
    if @season && @radius
      queries << build_query([:season, :radius], "/shiny/#{@season}/r-#{@radius}/")
    end
    if @width && @height && @radius
      queries << build_query([:shiny_word, :size], "/shiny/w-#{@width}/h-#{@height}/r-#{@radius}/")
    end
    if @radius
      queries << build_query([:shiny_word, :radius], "/shiny/r-#{@radius}/")
    end
    if @season
      queries << build_query([:season], "/shiny/#{@season}/")
    end

    queries.compact.uniq { |q| q[:url] }
  end

  # --- Block 4: Season variations when no season in URL (~6-9) ---
  def build_season_variations
    queries = []

    SEASONS.each do |season|
      if @width && @height && @radius
        queries << build_query([:season, :size], "/shiny/#{season}/w-#{@width}/h-#{@height}/r-#{@radius}/", season_override: season)
      end
      if @radius
        queries << build_query([:season, :radius], "/shiny/#{season}/r-#{@radius}/", season_override: season)
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
      w, h, r = parse_size_string(size_str)
      next unless w && h && r

      queries = []
      season = @season || SEASONS.sample
      url = "/shiny/#{season}/w-#{w}/h-#{h}/r-#{r}/"

      # Запрос: сезон + размер
      queries << {
        text: build_text_from_parts([:season, :size], season_override: season, size_override: [w, h, r]),
        url: url
      }

      # С вероятностью 40% — добавить бренд
      if rand < 0.4
        brand = promoted_brands.reject { |b| b[:slug] == @brand_slug }.sample
        if brand
          brand_url = "/shiny/#{season}/#{brand[:slug]}/w-#{w}/h-#{h}/r-#{r}/"
          queries << {
            text: build_text_from_parts([:season, :brand, :size], brand_name: brand[:name], brand_slug: brand[:slug], season_override: season, size_override: [w, h, r]),
            url: brand_url
          }
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

      # бренд + сезон + радиус
      if @brand_slug
        queries << {
          text: build_text_from_parts([:season, :brand, :radius], season_override: season, radius_override: r),
          url: "/shiny/#{season}/#{@brand_slug}/r-#{r}/"
        }
      end

      # сезон + радиус (без бренда)
      if rand < 0.5
        queries << {
          text: build_text_from_parts([:season, :radius], season_override: season, radius_override: r),
          url: "/shiny/#{season}/r-#{r}/"
        }
      end

      # бренд + радиус (без сезона) — изредка
      if @brand_slug && rand < 0.3
        queries << {
          text: build_text_from_parts([:brand, :radius], radius_override: r),
          url: "/shiny/#{@brand_slug}/r-#{r}/"
        }
      end
    end

    queries
  end

  def popular_sizes_for_radius
    key = @radius.to_s.to_sym
    TIRE_POPULAR_SIZES[key] || []
  end

  def parse_size_string(size_str)
    # "175/65 R14" or "205/65 R16C" -> [175, 65, 14]
    if size_str =~ /(\d+)\/(\d+)\s*R?(\d+)/i
      [$1, $2, $3]
    end
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
      size_name(override[0], override[1], override[2])
    else
      return nil unless @width && @height && @radius
      size_name(@width, @height, @radius)
    end
  end

  def format_radius_text(radius = nil)
    radius ||= @radius
    return nil unless radius
    case rand(1..4)
    when 1 then "R#{radius}"
    when 2 then "на #{radius}"
    when 3 then "р#{radius}"
    when 4 then "r#{radius}"
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
  def size_name(ww, hh, rr)
    case rand(1..120)
    when 1..5   then "#{ww} #{hh}R#{rr}"
    when 6..10  then "#{ww}/#{hh} R#{rr}"
    when 11..15 then "#{ww} #{hh} #{rr}"
    when 16..20 then "#{ww}/#{hh} R#{rr}"
    when 21..25 then "#{ww}/#{hh} #{rr}"
    when 26..30 then "#{ww}/#{hh} R#{rr}"
    when 31..40 then "#{ww} #{hh} R#{rr}"
    when 41..45 then "#{ww}х#{hh} #{rr}"
    when 46..50 then "#{ww}/#{hh}/#{rr}"
    when 51..55 then "#{ww}х#{hh} Р#{rr}"
    when 56..60 then "#{ww}/#{hh} р#{rr}"
    when 61..65 then "#{ww}/#{hh} на #{rr}"
    when 66..70 then "#{ww}/#{hh} на R#{rr}"
    when 71..80 then "#{ww}/#{hh}R#{rr}"
    when 81..85 then "R#{rr} на #{ww} #{hh}"
    when 86..90 then "р#{rr} на #{ww} #{hh}"
    when 91..95 then "#{ww} #{hh} #{rr}"
    when 96..100 then "#{ww}/#{hh}R#{rr}"
    else "#{ww} #{hh} R#{rr}"
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
