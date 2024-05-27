Пример запроса (тип1):
=================================================

curl -X POST -H "Content-Type: application/json"      -d '{"tyres": [
{
"brand": "michelin",
"model": "alpin",
"width": 205,
"height": 55,
"diameter": 16,
"season": 1,
"type_review": 1
},
{
"brand": "bridgestone",
"model": "blizzak",
"width": 185,
"height": 60,
"diameter": 14,
"season": 2,
"type_review": -1
}
]
}'       http://localhost:3000/api/v1/reviews

=========================================================


загрузить базу
получить модели для машин > 2005
очистить модели
написать загрузку с проверкой
сделать транслит для брендов и моделей
загрузить транслит
проба