local LoadTestHandler = {}

LoadTestHandler.PRIORITY = 1000
LoadTestHandler.VERSION = "1.0.0"

math.randomseed(os.time())

function toboolean(str)
    local bool = false
    if str == "true" then
        bool = true
    end
    return bool
end

function LoadTestHandler:access(config)
    -- Implement logic for the access phase here (http)
    kong.log(config.log_prefix)
    
    local load_test = toboolean(kong.request.get_query_arg("load_test"))
    local load_loops = tonumber(kong.request.get_query_arg("load_loops"))
    local load_log = toboolean(kong.request.get_query_arg("load_log"))
    local min_buffer_value = tonumber(kong.request.get_query_arg("min_buffer_value"))
    local max_buffer_value = tonumber(kong.request.get_query_arg("max_buffer_value"))
    
    if load_test then        
        if not load_loops then
            load_loops = 1000
        end
        
        if not min_buffer_value then
            min_buffer_value = -5
        end
        
        if not max_buffer_value then
            max_buffer_value = 5
        end
        
        if max_buffer_value <= min_buffer_value then
            max_buffer_value = min_buffer_value + 2
        end
        
        kong.log("\nload_loops: " .. load_loops .. "\nmin_buffer_value: " .. min_buffer_value .. "\nmax_buffer_value: " .. max_buffer_value)
        
        -- Load Test logic
        local counter = 0
        local value_buffer = 0
        while counter < load_loops do
            value_buffer = value_buffer + math.random(min_buffer_value, max_buffer_value)
            
            if load_log then
                kong.log("LOOP #" .. counter .. ": " .. value_buffer)
            end
            counter = counter + 1
        end
        kong.log("LoadTest: test ended with " .. counter .. " load loops. Buffer value: " .. value_buffer)
    end

    kong.log(config.log_suffix)
end

-- return the created table, so that Kong can execute it
return LoadTestHandler