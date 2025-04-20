# app/lib/tyre_constants.rb
module TyreConstants
  SEASON_ORDER = { "letnie" => 0, "vsesezonie" => 1, "zimnie" => 2 }
  HIGHLIGHT_PHRASES_RU = [
    "лучший выбор", "топ-модель сезона", "популярная модель",
    "рекомендуем к покупке", "выбор покупателей", "бестселлер",
    "идеально для вашего авто", "надежный выбор", "хит продаж"
  ].freeze


  HIGHLIGHT_PHRASES_UA = [
    "найкращий вибір", "топ-модель сезону", "популярна модель",
    "рекомендуємо до покупки", "вибір покупців", "бестселер",
    "ідеально для вашого авто", "надійний вибір", "хіт продажу"
  ].freeze


  TEMPLATES = [
    "%{highlight}: %{season_phrase} %{brand} %{name}",
    "%{season_phrase} %{brand} %{name}",
    "%{highlight}: %{brand} %{name}",
    "%{brand} %{name} — %{highlight}",
    "%{brand}: %{season_phrase} %{name}"
  ].freeze

  SEASON_TEXT_VARIANTS_RU = {
    "letnie" => ["летние шины", "шины на лето", "летняя резина", "автошины летние", "летние покрышки",
                 "авторезина на лето", "летние колеса", "летняя модель"],
    "zimnie" => ["зимние шины", "резина для зимы", "зимняя автошина", "шины на зиму", "зимняя покрышка",
                 "зимняя модель", "зимние колеса"],
    "vsesezonie" => ["всесезонные шины", "резина на все сезоны", "универсальные шины", "всесезонка", "всепогодная резина"]
  }.freeze


  SEASON_TEXT_VARIANTS_UA = {
    "letnie" => ["літні", "шини на літо", "літня гума", "літні покришки"],
    "zimnie" => ["зимові", "зимова гума", "зимові шини", "гума на зиму", "покришки на зиму"],
    "vsesezonie" => ["всесезонні", "гума на весь рік", "шини на всі сезони"]
  }.freeze

  SEASON_TITLES_RU = {
    "letnie" => "Летние шины",
    "zimnie" => "Зимние шины",
    "vsesezonie" => "Всесезонные шины"
  }.freeze

  SEASON_TITLES_UA = {
    "letnie" => "Летні шини",
    "zimnie" => "Зимові шини",
    "vsesezonie" => "Всесезонні шини"
  }.freeze

  def self.season_variants(language)
    language.to_s.downcase == "ua" ? SEASON_TEXT_VARIANTS_UA : SEASON_TEXT_VARIANTS_RU
  end

  def self.highlight_phrases(language)
    language.to_s.downcase == "ua" ? HIGHLIGHT_PHRASES_UA : HIGHLIGHT_PHRASES_RU
  end

  def self.season_titles(language)
    language.to_s.downcase == "ua" ? SEASON_TITLES_UA : SEASON_TITLES_RU
  end
end
