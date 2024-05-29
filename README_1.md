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
"type_review": 1,
"id": "m1"
},
{
"brand": "bridgestone",
"model": "blizzak",
"width": 185,
"height": 60,
"diameter": 14,
"season": 2,
"type_review": -1,
"id": "m567"
}
]
}'       http://localhost:3000/api/v1/reviews

=========================================================

Пример запроса (тип2):
=================================================

curl -X POST -H "Content-Type: application/json"      -d '{
"brand": "michelin",
"model": "alpin",
"season": 1,
"grade": 7.6,
"number_of_reviews": 10,
"sizes_of_model" : [
{"width": 205, "height": 55, "diameter": 16, "id": "m1"},
{"width": 175, "height": 70, "diameter": 14, "id": "m22"},
{"width": 185, "height": 55, "diameter": 15, "id": "m321"},
{"width": 235, "height": 55, "diameter": 18, "id": "m45"}
]
}'       http://localhost:3000/api/v1/reviews_for_model

=========================================================

