const fs = require('fs');
const file = 'pb_migrations/1787585876_collections_snapshot.js';
let content = fs.readFileSync(file, 'utf8');

// Extract the snapshot array string
const match = content.match(/const snapshot = (\[.*\]);\n\n  return app.importCollections/s);
if (!match) throw new Error("Could not find snapshot array");

let snapshot = JSON.parse(match[1]);

// 1. Add credits to users
const usersCol = snapshot.find(c => c.name === 'users');
usersCol.fields.push({
  "hidden": false,
  "id": "number_credits_id",
  "name": "credits",
  "presentable": false,
  "required": false,
  "system": false,
  "type": "number",
  "max": null,
  "min": 0,
  "noDecimal": false
});

// 2. Add settings collection
snapshot.push({
  "createRule": null,
  "deleteRule": null,
  "fields": [
    {
      "autogeneratePattern": "[a-z0-9]{15}",
      "hidden": false,
      "id": "text3208210256",
      "max": 15,
      "min": 15,
      "name": "id",
      "pattern": "^[a-z0-9]+$",
      "presentable": false,
      "primaryKey": true,
      "required": true,
      "system": true,
      "type": "text"
    },
    {
      "hidden": false,
      "id": "text_provider",
      "name": "provider",
      "required": true,
      "type": "text"
    },
    {
      "hidden": false,
      "id": "text_apiKey",
      "name": "apiKey",
      "required": true,
      "type": "text"
    }
  ],
  "id": "pbc_settings123",
  "indexes": [],
  "listRule": null,
  "name": "settings",
  "system": false,
  "type": "base",
  "updateRule": null,
  "viewRule": null
});

// 3. Add apiLogs collection
snapshot.push({
  "createRule": null,
  "deleteRule": null,
  "fields": [
    {
      "autogeneratePattern": "[a-z0-9]{15}",
      "hidden": false,
      "id": "text3208210256",
      "max": 15,
      "min": 15,
      "name": "id",
      "pattern": "^[a-z0-9]+$",
      "presentable": false,
      "primaryKey": true,
      "required": true,
      "system": true,
      "type": "text"
    },
    {
      "hidden": false,
      "id": "relation_user",
      "name": "user",
      "required": true,
      "type": "relation",
      "cascadeDelete": true,
      "collectionId": "_pb_users_auth_",
      "maxSelect": 1,
      "minSelect": 0
    },
    {
      "hidden": false,
      "id": "number_tokensUsed",
      "name": "tokensUsed",
      "required": true,
      "type": "number"
    },
    {
      "hidden": false,
      "id": "number_cost",
      "name": "cost",
      "required": true,
      "type": "number"
    },
    {
      "hidden": false,
      "id": "text_provider_log",
      "name": "provider",
      "required": true,
      "type": "text"
    },
    {
      "hidden": false,
      "id": "text_status",
      "name": "status",
      "required": true,
      "type": "text"
    }
  ],
  "id": "pbc_apilogs123",
  "indexes": [],
  "listRule": "@request.auth.id = user",
  "name": "apiLogs",
  "system": false,
  "type": "base",
  "updateRule": null,
  "viewRule": "@request.auth.id = user"
});

// Reconstruct file
const newContent = content.replace(match[1], JSON.stringify(snapshot, null, 2));
fs.writeFileSync(file, newContent);
console.log("Migration patched successfully.");
