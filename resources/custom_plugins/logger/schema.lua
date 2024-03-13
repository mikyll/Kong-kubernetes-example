return {
  name = "logger",
  fields = {
    {
      config = {
        type = "record",
        fields = {
          {
            logger_prefix = {
              type = "string",
              default = "LOG: ",
            },
          },
          {
            logger_suffix = {
              type = "string",
              default = ".",
            },
          },
        },
      },
    },
  }
}