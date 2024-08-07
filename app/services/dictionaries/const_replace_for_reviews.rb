# числовые ключи у хешей используются для определения вероятности замены.
# в rand(1..100) % key == 0 будет верно, когда rand(1..100) возвращает число, которое делится на key без остатка.
# Если key равен 1, любое число от 1 до 10 будет делиться на 1 без остатка, поэтому проверка rand(1..10) % 1 == 0 будет истинной всегда.

HASH_DELETE_TEXT_RU = {
  # ключ 1 - удаление, остальные вероятность, пример: ключ 4 - это 25% выпадание
  1 => [
    /\bМария\b/i,
    /^(\s*|)\bОднажды\b[^.]*\./i,
    /летней эксплуатации|для безопасности/i,
    /ДЛЯ ТРЕБОВАТЕЛЬНЫХ ВОДИТЕЛЕЙ(\s*|)(С ОПЫТОМ ЗА РУЛЁМ|)/i,
    /, кто ценит комфорт и безопасность!/,
    /(Братцы|Друзья|Дорогие друзья|Мужики|Блин|парни(ша|)|хлоп|ребята|девчонки)(\s*|)(,|!|)/i,
    /(мой|)(Нейтральный|Позитивный|Негативный|Положительный|Отрицательный) отзыв/i,
    /(Ого(в|)|Ой|Эй|Эх)(\s*|)(,|!|)/i
  ],
  4 => [
    /\bэт(о|и)\b/i,
    /на любо(й|м) (покрытии|трассе|поверхности|дороге)/i
  ]

}

HASH_DELETE_TEXT_UA = {
  # ключ 1 - удаление, остальные вероятность, пример: ключ 4 - это 25% выпадание
  1 => [
    /\bМарія\b/i,
    /^(\s*|)\b(Одного разу|Якось)\b[^.]*\./i,
    /літньої експлуатації|для безпеки/i,
    /, хто цінує комфорт та безпеку!/,
    /(Братці|Друзі|Дорогі друзі|Чоловіки|Млинець|хлопче|хлоп(ці|чата|)|дівчат(к|)а)(\s*|)(,|!|)/i,
    /(мій|)(Нейтральний|Позитивний|Негативний|Позитивний|Негативний) відгук/i,
    /(Ого(в|)|Ой|Гей|Ех)(\s*|)(,|!|)/i
  ],

  4 => [
    /\bце|ці\b/i,
    /на будь-як(ому|ій) (покритті|трасі|поверхні|дорозі)/i
  ]
}

HASH_REPLACE_TEXT_RU = {
  # замена всегда при совпадении

}
HASH_REPLACE_TEXT_UA = {
  # замена всегда при совпадении
  "галасливі" => "шумні",
  "галасливість" => "шумність",
  "галасують" => "шумлять",
  "галаслива" => "шумна",
  "гучність"=> "шумність",
}

SINONIMS = {
  :ru => [
    ["плохая", "плоха", "никакая", "паршивая", "ужасная", "отвратительная", "неудовлетворительная",
     "скверная", "жуткая", "дрянная", "некачественная"],
    ["хорошая", "хороша", "отличная", "прекрасная", "замечательная", "великолепная", "превосходная",
     "супер", "восхитительная", "шикарная", "качественная", "потрясающая", "безупречная", "идеальная", "удивительная", "блестящая"],
    ["идеальный", "совершенный", "безупречный", "превосходный", "великолепный", "безукоризненный", "образцовый",
     "отличный", "наилучший", "эталонный", "исключительный", "замечательный", "потрясающий", "шикарный", "восхитительный"],
    ["управляемость", "контроль", "рулёжка", "маневренность", "курсовая устойчивость", "стабильность", "управление",
     "обратная связь", "чувствительность", "реактивность", "точность", "реагирование"],
    ["безопасность ", "защищенность", "спокойствие", "надежность", "спокойствие "],
    ["комфорт", "удобство", "спокойствие", "комфортабельность", "комфортность"],
    ["цена", "стоимость"],
    ["плохо", "дурно", "скверно", "ужасно", "отвратительно", "плачевно", "паршиво", "грустно", "печально", "неудовлетворительно", "безобразно"],
    ["хорошо", "отлично", "прекрасно", "замечательно", "великолепно", "превосходно", "восхитительно", "шикарно",
     "супер", "потрясающе", "безупречно", "идеально"],
    ["провал", "крах", "разгром", "облом", "кошмар"],
    ["катастрофа", "трагедия", "авария", "драма"],
    ["нейтральный", "такой себе", "так себе", "посредственный", "средненький", "обычный", "средний", "заурядный"],
  ],

  :ua => [
    ["погана", "ніяка", "жахлива", "відразлива", "незадовільна", "паршива", "жахлива", "неякісна"],
    ["хороша", "відмінна", "прекрасна", "чудова", "велична", "відмінна", "супер", "захоплююча", "шикарна",
     "якісна", "вражаюча", "бездоганна", "ідеальна", "дивовижна", "блискуча"],
    ["ідеальний", "досконалий", "бездоганний", "відмінний", "величний", "бездоганний", "зразковий", "відмінний",
     "найкращий", "еталонний", "винятковий", "чудовий", "вражаючий", "шикарний", "захоплюючий"],
    ["керованість", "контроль", "керування", "маневреність", "курсова стійкість", "стабільність", "управління",
     "зворотний зв'язок", "чутливість", "реактивність", "точність", "реагування"],
    ["безпека", "захищеність", "спокій", "надійність"],
    ["комфорт", "зручність", "спокій", "комфортабельність", "комфортність"],
    ["ціна", "вартість"],
    ["погано", "жахливо", "відразливо", "плачевно", "паршиво", "жахливо", "сумно", "незадовільно", "потворно"],
    ["добре", "відмінно", "прекрасно", "велично", "захоплююче", "шикарно", "супер", "вражаюче", "бездоганно", "ідеально", "чудово"],
    ["провал", "крах", "розгром", "облом", "кошмар"],
    ["катастрофа", "трагедія", "аварія", "драма"],
    ["нейтральний", "такий собі", "так собі", "посередній", "середній", "звичайний", "заурядний"]
  ]
}
