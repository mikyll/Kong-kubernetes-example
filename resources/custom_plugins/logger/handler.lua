local LoggerHandler = {}

LoggerHandler.PRIORITY = 1000
LoggerHandler.VERSION = "1.0.0"

function LoggerHandler:log(config)
    -- Implement logic for the log phase here (http/stream)
    kong.log(config.logger_prefix)
    
    if config.load_test then
        -- load test logic (for?)
    end
    
    kong.log(config.logger_suffix)
end

-- return the created table, so that Kong can execute it
return LoggerHandler