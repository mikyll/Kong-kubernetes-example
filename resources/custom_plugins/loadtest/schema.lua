return {
  name = "loadtest",
  fields = {
    {
      config = {
        type = "record",
        fields = {
          {
            log_prefix = {
              type = "string",
              required = false,
              default = "LOG: ",
            },
          },
          {
            log_suffix = {
              type = "string",
              required = false,
              default = ".",
            },
          },
        },
      },
    },
  }
}