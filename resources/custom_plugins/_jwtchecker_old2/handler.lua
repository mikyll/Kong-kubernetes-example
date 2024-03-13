local JWTCheckerHandler = {}

-- Description:
-- This plugin does
-- 
-- 

JWTCheckerHandler.PRIORITY = 1000
JWTCheckerHandler.VERSION = "1.0.0"
JWTCheckerHandler.NAME = "headermanipulator"

--======================================================================
-- UTILITY FUNCTIONS
--======================================================================

-- This function removes the specified substring from a given string.
-- @param str: The original string.
-- @param substr: The substring to be removed.
-- @return: Returns the modified string with the substring removed.
function removeSubstring(str, substr)
  -- Find the starting index of the substring in the string.
  local startIndex, endIndex = string.find(str, substr)

  -- If the substring is found, remove it from the string.
  if startIndex and endIndex
  then
    local prefix = string.sub(str, 1, startIndex - 1)
    local suffix = string.sub(str, endIndex + 1)
    return prefix .. suffix
  end

  -- If the substring is not found, return the original string.
  return str
end

-- Split the specified string in a array of strings
-- @param inputstr: The original string.
-- @param sep: The separator.
function stringSplit(inputstr, sep)
	if sep == nil
    then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)")
    do
		table.insert(t, str)
	end
	return t
end

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
-- encoding
function enc(data)
  return ((data:gsub('.', function(x) 
    local r,b='',x:byte()
    for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
    return r;
  end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if (#x < 6) then return '' end
    local c=0
    for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
    return b:sub(c+1,c+1)
  end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
function dec(data)
  data = string.gsub(data, '[^'..b..'=]', '')
  return (data:gsub('.', function(x)
    if (x == '=') then return '' end
    local r,f='',(b:find(x)-1)
    for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
    return r;
  end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if (#x ~= 8) then return '' end
    local c=0
    for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
      return string.char(c)
  end))
end

--======================================================================
-- KONG PLUGIN FUNCTIONS 
--======================================================================

function JWTCheckerHandler:access(config)
    -- Initialize or modify request-specific data
    ngx.ctx.requestData = {}
end

function JWTCheckerHandler:header_filter(config)
  -- test: log all the headers present in the request
  local headerStr = "Request headers:\n"
  for headerName, headerValue in pairs(kong.request.get_headers(30))
  do
    headerStr = headerStr .. " - " .. headerName .. ": " .. headerValue .. "\n"
  end
  kong.log("LOG: \n", headerStr)

  local authHeaderValue = kong.request.get_header('authorization')
  if authHeaderValue
  then
    kong.log("LOG: authorization found\n")

    local token = removeSubstring(authHeaderValue, "Bearer ")
    kong.log("LOG: token: ", token, "\n")

    local tokenParts = stringSplit(token, ".")

    local tokenHeader = dec(tokenParts[1])
    kong.log("LOG: tokenHeader: ", tokenHeader, "\n")
    
    local tokenType = tokenHeader:gsub("%s+", "")
    tokenType = tokenType:lower()
    kong.log("LOG: tokenType: ", tokenType, "\n")

    if string.find(tokenType, '"typ":"jwt"')
    then
      kong.log("LOG: found JWT token")

      -- increase body content length
      local lengthHeaderValue = kong.response.get_header('content_length')
      if lengthHeaderValue
      then
        kong.log("LOG: current Content-Length: ", lengthHeaderValue)
        kong.response.clear_header('content_length')
        
        -- We need to clear the 'Content-Length' header if we want to change the body
        kong.log("LOG: new Content-Length: ", kong.response.get_header('content_length'))
      end

      JWTCheckerHandler.token = token
      JWTCheckerHandler.tokenParts = tokenParts
      JWTCheckerHandler.authorized = true
      kong.response.set_header("Authorized", "TRUE")
    else
      kong.response.set_header("Authorized", "FALSE")
    end
  else
    kong.log("LOG: authorization not found\n")

    JWTCheckerHandler.authorized = false
    kong.response.set_header("Authorized", "FALSE")
  end
end

function JWTCheckerHandler:body_filter(config)
  local chunk, eof = kong.response.get_raw_body()

  -- When we receive a chunk we add the data to ngx.ctx.requestData
  if chunk
  then
    table.insert(ngx.ctx.requestData, chunk)
  end
  
  -- When the response is fully sent (last chunk)
  if eof
  then
    local fullBody = table.concat(ngx.ctx.requestData)
    
    kong.log("LOG: JWTCheckerHandler.authorized: ", JWTCheckerHandler.authorized)
    if JWTCheckerHandler.authorized == true
    then
      -- get payload from JWT token
      local tokenPayload = dec(JWTCheckerHandler.tokenParts[2])
      
      local message = "You're authorized! Welcome " .. tokenPayload
      
      -- Add the message to the body of the request
      local newBody = 
      kong.response.set_raw_body(fullBody .. "\n\n" .. message)
    else
      kong.response.set_raw_body("You're not authorized.")
    end
  end
end

function JWTCheckerHandler:response(config)
  kong.log("LOG.response: start\n")
  
  -- Process the headers
  local authHeaderValue = kong.request.get_header('authorization')
  if authHeaderValue
  then
    kong.log("LOG.response: authorization header found\n")

    if string.find(authHeaderValue, "Bearer")
    then
      kong.log("LOG.response: Bearer authorization type\n")

      local token = removeSubstring(authHeaderValue, "Bearer ")
      kong.log("LOG.response: token: ", token, "\n")

      local tokenParts = stringSplit(token, ".")

      local tokenHeader = dec(tokenParts[1])
      kong.log("LOG.response: tokenHeader: ", tokenHeader, "\n")
      
      local tokenType = tokenHeader:gsub("%s+", "")
      tokenType = tokenType:lower()
      kong.log("LOG.response: tokenType: ", tokenType, "\n")

      if string.find(tokenType, '"typ":"jwt"')
      then
        kong.log("LOG.response: found JWT token\n")

        -- increase body content length
        local lengthHeaderValue = kong.response.get_header('content_length')
        if lengthHeaderValue
        then
          kong.log("LOG.response: current Content-Length: ", lengthHeaderValue)
          kong.response.clear_header('content_length')
          
          -- We need to clear the 'Content-Length' header if we want to change the body
          kong.log("LOG.response: new Content-Length: ", kong.response.get_header('content_length'))
        end

        JWTCheckerHandler.token = token
        JWTCheckerHandler.tokenParts = tokenParts
        JWTCheckerHandler.authorized = true
        kong.response.set_header("Authorized", "TRUE")
      else
        kong.response.set_header("Authorized", "FALSE")
      end

    end    
  else
    kong.log("LOG.response: authorization not found\n")

    JWTCheckerHandler.authorized = false
    kong.response.set_header("Authorized", "FALSE")
  end
  
  -- Process the body
  local body = kong.response.get_raw_body()
  if body
  then
    kong.log("LOG.response: JWTCheckerHandler.authorized: ", JWTCheckerHandler.authorized)
    if JWTCheckerHandler.authorized == true
    then
      kong.log("LOG.response: authorization not found\n")
      
      -- Get payload of JWT token
      local tokenPayload = dec(JWTCheckerHandler.tokenParts[2])
      
      local message = "You're authorized! Welcome " .. tokenPayload
      
      -- Add the message to the body of the request
      kong.response.set_raw_body(fullBody .. "\n\n" .. message)
    else
      kong.response.set_raw_body("You're not authorized.")
    end
  end
end

-- return the created table, so that Kong can execute it
return JWTCheckerHandler

-- PDK References
-- 
-- kong.response
-- docs: https://docs.konghq.com/gateway/latest/plugin-development/pdk/kong.response/
--