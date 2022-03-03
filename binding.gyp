{
  "conditions": [
    ["OS=='mac'", {
      "targets": [
        {
          "type": "executable",
          "mac_bundle": 1,
          "target_name": "<!(node_modules/node-jq/bin/jq -r .name package.json)",
          "product_name": "<!(node_modules/node-jq/bin/jq -r .productName package.json)",
          "sources": [
            "<!@(find lib -iname '*.m')",
            "<!@(find lib -iname '*.js')",
            "<!@(find templates -iname '*.mustache')",
            "<!@(find src -iname '*.js' -o -iname '*.jsx')"
          ],
          "actions": [{
            "action_name": "bundling",
            "inputs": [
              "<!@(find lib -iname '*.js')",
              "<!@(find src -iname '*.js' -o -iname '*.jsx')"
            ],
            "outputs": ["<(INTERMEDIATE_DIR)/main.bundle.js"],
            "action": ["node_modules/.bin/esbuild", "<!(node_modules/node-jq/bin/jq -r .main package.json)", "--bundle", "--outfile=<(INTERMEDIATE_DIR)/main.bundle.js"]
          }],
          "rules": [{
            "rule_name": "templating",
            "extension": "mustache",
            "outputs": ["<(INTERMEDIATE_DIR)/templates/<(RULE_INPUT_ROOT)"],
            "action": ["node_modules/.bin/mustache", "package.json", "<(RULE_INPUT_PATH)", "<(INTERMEDIATE_DIR)/templates/<(RULE_INPUT_ROOT)"]
          }],
          "copies": [{
            "destination": "<(PRODUCT_DIR)/<(_product_name).app/Contents",
            "files": ["<(INTERMEDIATE_DIR)/templates/Info.plist"]
          }, {
            "destination": "<(PRODUCT_DIR)/<(_product_name).app/Contents/Resources",
            "files": ["<(INTERMEDIATE_DIR)/main.bundle.js"]
          }],
          "xcode_settings": {
            "MACOSX_DEPLOYMENT_TARGET": "11.0",
            "CLANG_ENABLE_MODULES": "YES",
            "CLANG_ENABLE_OBJC_ARC": "YES"
          }
        }
      ]
    }]
  ]
}
