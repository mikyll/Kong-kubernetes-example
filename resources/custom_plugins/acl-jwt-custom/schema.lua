local typedefs = require "kong.db.schema.typedefs"

return {
  name = "acl-jwt-custom",
  fields = {
    {
      config = {
        type = "record",
        fields = {
          { verbose = { type = "boolean", default = false, required = false, description = "An optional boolean that indicates if the plugin must add the message at the end of the response body. The message indicates if the user is authorized and if it is, it prints the payload", }, },
          { acl = { description = "ACL mappings", type = "map", required = false, keys = { type = "string" }, values = { type = "array", required = false, elements = { type = "string" }, }, }, },
        },
      },
    },
  }
}