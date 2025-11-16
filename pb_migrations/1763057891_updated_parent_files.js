/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_2644283644")

  // update collection data
  unmarshal({
    "createRule": "@request.method = \"POST\"",
    "deleteRule": "id != \"\"",
    "updateRule": "id != \"\"",
    "viewRule": "id != \"\""
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_2644283644")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.id != \"\"",
    "deleteRule": "@request.auth.id = firebase_uid",
    "updateRule": "@request.auth.id = firebase_uid",
    "viewRule": "@request.auth.id = firebase_uid\n"
  }, collection)

  return app.save(collection)
})
