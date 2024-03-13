local typedefs = require "kong.db.schema.typedefs"

return {
  name = "jwtchecker",
  fields = {
    {
      config = {
        type = "record",
        fields = {
          { 
            verbose = {
              type = "boolean",
              default = true,
              required = false,
              description = "An optional boolean that indicates if the plugin must add the message at the end of the response body. The message indicates if the user is authorized and if it is, it prints the payload",
            },
            -- Other fields to configure the plugin (e.g. key to validate the JWT)
            
            -- Placeholder for other fields. Each additional field should be its own table within this 'fields' array.
            -- {
            --   my_other_field = {
            --     type = "string", -- Example type
            --     default = "default_value", -- Example default value
            --     required = false,
            --     description = "Description of what this field does.",
            --   },
            -- },
          }
        },
      },
    },
  }
}