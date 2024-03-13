local CustomLoggerHandler = {}

CustomLoggerHandler.PRIORITY = 1000
CustomLoggerHandler.VERSION = "1.0.0"
CustomLoggerHandler.NAME = "custom_logger"

--======================================================================
-- UTILITY FUNCTIONS --------------------------------------------------=
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
-- PLUGIN FUNCTIONS ---------------------------------------------------=
--======================================================================

function CustomLoggerHandler:header_filter(config)
  -- Implement logic for the header_filter phase here (http)
  kong.log("MyLOG: header_filter")
  
  -- Log all the headers present in the request
  local headerStr = "Request headers:\n"
  for headerName, headerValue in pairs(kong.request.get_headers(30))
  do
    headerStr = headerStr .. " - " .. headerName .. ": " .. headerValue .. "\n"
  end
  kong.log("MyLOG: \n", headerStr)

  local authHeaderValue = kong.request.get_header('authorization')
  if authHeaderValue
  then
    kong.log("MyLOG: authorization header found\n")

    local token = removeSubstring(authHeaderValue, "Bearer ")
    kong.log("MyLOG: token: ", token, "\n")

    local tokenParts = stringSplit(token, ".")

    local tokenHeader = dec(tokenParts[1])
    kong.log("MyLOG: tokenHeader: ", tokenHeader, "\n")
    
    local tokenType = tokenHeader:gsub("%s+", "")
    tokenType = tokenType:lower()
    kong.log("MyLOG: tokenType: ", tokenType, "\n")

    if string.find(tokenType, '"typ":"jwt"')
    then
      kong.log("MyLOG: found JWT token")

      -- increase body content length
      local lengthHeaderValue = kong.response.get_header('content_length')
      if lengthHeaderValue
      then
        kong.log("MyLOG: current Content-Length: ", lengthHeaderValue)
        kong.response.clear_header('content_length')
        kong.log("MyLOG: new Content-Length: ", kong.response.get_header('content_length'))
      end

      CustomLoggerHandler.token = token
      CustomLoggerHandler.tokenParts = tokenParts
      CustomLoggerHandler.authorized = true
      kong.response.set_header("Authorized", "TRUE")
    else
      kong.response.set_header("Authorized", "FALSE")
    end
  else
    kong.log("MyLOG: authorization not found\n")

    CustomLoggerHandler.authorized = false
    kong.response.set_header("Authorized", "FALSE")
  end
end

function CustomLoggerHandler:body_filter(config)
  -- Implement logic for the body_filter phase here (http)
  kong.log("MyLOG: body_filter")

  local currentBody = kong.response.get_raw_body()

  kong.log("MyLOG: CustomLoggerHandler.authorized: ", CustomLoggerHandler.authorized)
  if CustomLoggerHandler.authorized == true
  then
    -- get issuer
    local tokenPayload = dec(CustomLoggerHandler.tokenParts[2])
    local message = "You're authorized! Welcome " .. tokenPayload
    if currentBody
    then
      kong.response.set_raw_body(currentBody .. message)
    else
      kong.response.set_raw_body(message)
    end
  end
end

-- return the created table, so that Kong can execute it
return CustomLoggerHandler
