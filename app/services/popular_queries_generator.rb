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

  def generate(count = 25)
    queries = []
    queries.concat(build_combinations)
    queries.concat(build_brand_variations)
    queries.concat(build_general_queries)
    queries.shuffle.first(count)
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
        # Potential brand slug — verify against promoted brands
        if promoted_brands.any? { |b| b[:slug] == part }
          @brand_slug = part
        end
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

  # --- Block 2: Other brands (~10-15) ---
  def build_brand_variations
    other_brands = promoted_brands.reject { |b| b[:slug] == @brand_slug }
    selected = other_brands.sample(rand(10..15))

    selected.flat_map do |brand|
      queries = []
      # Query 1: brand + current size/season params
      parts_for_query = [:brand]
      url_parts = [brand[:slug]]

      if @season
        parts_for_query.unshift(:season)
        url_parts.unshift(@season)
      end

      if @width && @height && @radius
        parts_for_query << :size
        url_suffix = "w-#{@width}/h-#{@height}/r-#{@radius}"
        link_url = "/shiny/#{url_parts.join('/')}/#{url_suffix}/"
      elsif @radius
        parts_for_query << :radius
        link_url = "/shiny/#{url_parts.join('/')}/r-#{@radius}/"
      else
        link_url = "/shiny/#{url_parts.join('/')}/"
      end

      text = build_text_from_parts(parts_for_query, brand_name: brand[:name], brand_slug: brand[:slug])
      queries << { text: text, url: link_url }

      # Optionally add a second query (~50% chance) with only brand + radius
      if rand < 0.5 && @radius && (@width && @height)
        alt_parts = [:brand]
        alt_parts.unshift(:season) if @season && rand < 0.5
        alt_parts << :radius
        alt_url_parts = []
        alt_url_parts << @season if alt_parts.include?(:season)
        alt_url_parts << brand[:slug]
        alt_link = "/shiny/#{alt_url_parts.join('/')}/r-#{@radius}/"

        text2 = build_text_from_parts(alt_parts, brand_name: brand[:name], brand_slug: brand[:slug])
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
      queries << build_query([:size], "/shiny/w-#{@width}/h-#{@height}/r-#{@radius}/")
      # Extra variant with just "шины" word + size
      queries << build_query([:shiny_word, :size], "/shiny/w-#{@width}/h-#{@height}/r-#{@radius}/")
    end
    if @radius
      queries << build_query([:shiny_word, :radius], "/shiny/r-#{@radius}/")
    end
    if @season
      queries << build_query([:season], "/shiny/#{@season}/")
    end

    # Remove duplicates with block 1 by URL
    queries.compact.uniq { |q| q[:url] }
  end

  # --- Text formatting helpers ---

  def build_query(parts, url)
    { text: build_text_from_parts(parts), url: url }
  end

  def build_text_from_parts(parts, brand_name: nil, brand_slug: nil)
    components = parts.map do |part|
      case part
      when :season
        format_season_text
      when :brand
        format_brand_text(brand_name || current_brand_name, brand_slug || @brand_slug)
      when :size
        format_size_text
      when :radius
        format_radius_text
      when :shiny_word
        shiny_words.sample
      end
    end.compact

    components.shuffle.join(' ')
  end

  def format_season_text
    return nil unless @season
    variants = season_text_variants[@season]
    variants&.sample
  end

  def format_size_text
    return nil unless @width && @height && @radius
    size_name(@width, @height, @radius)
  end

  def format_radius_text
    return nil unless @radius
    case rand(1..4)
    when 1 then "R#{@radius}"
    when 2 then "на #{@radius}"
    when 3 then "р#{@radius}"
    when 4 then "r#{@radius}"
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
