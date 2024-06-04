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


curl "http://192.168.3.145:3003/api/v1/create_review_templates?min=10000&max=20000"
curl "http://192.168.3.145:3003/api/v1/create_review_templates?min=20000&max=25000"
curl "http://192.168.3.145:3003/api/v1/create_review_templates?min=25000&max=30000"
curl "http://192.168.3.145:3003/api/v1/create_review_templates?min=30000&max=35000"
curl "http://192.168.3.145:3003/api/v1/create_review_templates?min=35000&max=40000"
curl "http://192.168.3.145:3003/api/v1/create_review_templates?min=40000&max=45000"
curl "http://192.168.3.145:3003/api/v1/create_review_templates?min=45000&max=50000"

удалить все по двоеточие
и вывести в отдельный файл все с маленькой буквы и все не кириллица 