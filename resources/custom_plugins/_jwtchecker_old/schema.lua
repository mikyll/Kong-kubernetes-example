local typedefs = require "kong.db.schema.typedefs"

return {
    name = "jwtchecker",
    fields = {
        {
            config = {
                type = "record",
                fields = {

                },
            },
        },
    }
}