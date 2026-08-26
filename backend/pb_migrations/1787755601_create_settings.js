/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("settings");
  
  // Add ai_url field if it doesn't exist
  if (!collection.fields.getByName("ai_url")) {
    collection.fields.add(new Field({
      id: "text_ai_url_01",
      name: "ai_url",
      type: "text",
      required: false
    }));
  }

  // Add token field if it doesn't exist
  if (!collection.fields.getByName("token")) {
    collection.fields.add(new Field({
      id: "text_token_01",
      name: "token",
      type: "text",
      required: false
    }));
  }

  app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("settings");
  
  const aiUrlField = collection.fields.getByName("ai_url");
  if (aiUrlField) {
    collection.fields.removeById(aiUrlField.id);
  }

  const tokenField = collection.fields.getByName("token");
  if (tokenField) {
    collection.fields.removeById(tokenField.id);
  }

  app.save(collection);
})
