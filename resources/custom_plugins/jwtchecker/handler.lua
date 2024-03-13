--[[
JWT Checker Custom Plugin (Kong 3.6.0)

===============================================================================

Questo plugin controlla se nella richiesta è presente un token JWT:
- se è presente, la risposta del backend service verrà propagata al
  client con status code 200.
- se non è presente, verrà restituita una risposta vuota con status
  code:
  - 401 (Unauthorized) se non è proprio presente un header Authorization;
  - 403 (Forbidden) se è presente un header Authorization ma non è un JWT.
  
Inoltre, il plugin espone un parametro di configurazione (impostabile tramite
l'istanza Kubernetes del relativo KongPlugin) 'verbose'. Se questo è impostato
a true, al body della risposta viene aggiunto il messaggio:
- "You're authorized! Payload: <token_payload>", se nell'header della richiesta
  era presente un token JWT;
- "You're not authorized. No JWT token was found", viceversa.

Inoltre, il plugin aggiunge anche un header "X-JwtChecker-Authorized" alla
risposta, che indica se la richiesta conteneva un token JWT oppure no.

===============================================================================

I plugin Kong permettono di iniettare logica custom in diverse fasi di
esecuzione del ciclo di vita del gateway.

I plugin Kong funzionano a "fasi". Ogni fase definisce un contesto, in cui
è possibile implementare logica custom, relativa ai diversi entry-point del
ciclo di vita del Gateway.

Riferimenti (PDK):
-- kong.response
-- docs: https://docs.konghq.com/gateway/latest/plugin-development/pdk/kong.response/
--
--]]

local JWTCheckerHandler = {}

JWTCheckerHandler.PRIORITY = 1000
JWTCheckerHandler.VERSION = "1.0.0"
JWTCheckerHandler.NAME = "jwtchecker"

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
-- KONG PLUGIN LOGIC 
--======================================================================

-- This function is executed when all response headers bytes have been
-- received from the upstream service (backend).
function JWTCheckerHandler:header_filter(config)
  kong.log("LOG.header_filter: start\n")
  
  -- Process the headers
  JWTCheckerHandler.authorized = false
  local authHeaderValue = kong.request.get_header('authorization')
  
  -- Check if there's an 'Authorization' header
  if authHeaderValue
  then
    kong.log("LOG.header_filter: authorization header found\n")
  
    -- Check if the header contains 'Bearer'
    if string.find(authHeaderValue, "Bearer")
    then
      kong.log("LOG.header_filter: Bearer authorization type\n")

      local token = removeSubstring(authHeaderValue, "Bearer ")
      kong.log("LOG.header_filter: token: ", token, "\n")

      local tokenParts = stringSplit(token, ".")

      local tokenHeader = dec(tokenParts[1])
      kong.log("LOG.header_filter: tokenHeader: ", tokenHeader, "\n")
      
      local tokenType = tokenHeader:gsub("%s+", "")
      tokenType = tokenType:lower()
      kong.log("LOG.header_filter: tokenType: ", tokenType, "\n")

      -- If we found a JWT token in the request header
      if string.find(tokenType, '"typ":"jwt"')
      then
        kong.log("LOG.header_filter: found JWT token\n")

        -- Save the token for later (body_filter)
        JWTCheckerHandler.token = token
        JWTCheckerHandler.tokenParts = tokenParts
        JWTCheckerHandler.authorized = true
        
        -- Set status code 200: OK
        kong.response.set_status(200)
      else
        -- Set status code 403: Forbidden
        kong.response.set_status(403)
      end
    end
  else
    kong.log("LOG.header_filter: authorization not found\n")
    
    -- Set status code 401: Unauthorized
    kong.response.set_status(401)
  end
  
  -- Find the "Content-Length" header (default headers conversion: Content-Length -> content_length)
  local lengthHeaderValue = kong.response.get_header('content_length')
  if lengthHeaderValue
  then
    kong.log("LOG.header_filter: current Content-Length: ", lengthHeaderValue)
    kong.response.clear_header('content_length')
    
    -- We need to clear the 'Content-Length' header if we want to change the body
    kong.log("LOG.header_filter: new Content-Length: ", kong.response.get_header('content_length'))
  end
  
  -- Set header in response
  kong.response.set_header("X-JwtChecker-Authorized", string.upper(tostring(JWTCheckerHandler.authorized)))
  
  kong.log("LOG.header_filter: end\n")
end

-- This function is executed for each chunk of the response body received from
-- the upstream service (backend). This function can be called multiple time if
-- the response is large. However, kong.response.get_raw_body() returns the full
-- only when it's available, while it returns nil in other cases.
function JWTCheckerHandler:body_filter(config)
  kong.log("LOG.body_filter: start\n")
  
  -- Process the body
  local body = kong.response.get_raw_body()
  
  -- Only executed when the last chunk has been read
  if body
  then
    kong.log("LOG.body_filter: body: \n", body)
    kong.log("LOG.body_filter: JWTCheckerHandler.authorized: ", JWTCheckerHandler.authorized, "\n")
    
    if JWTCheckerHandler.authorized == true
    then
      kong.log("LOG.body_filter: JWT found.\n")
      
      -- Get payload of JWT token
      local tokenPayload = dec(JWTCheckerHandler.tokenParts[2])
      
      local message = "You're authorized! Payload: " .. tokenPayload
      
      if config.verbose
      then
        -- Add the message to the body of the request
        kong.response.set_raw_body(body .. "\n" .. message)
      end
    else
      kong.log("LOG.body_filter: JWT not found.\n")
      
      if config.verbose
      then
        -- Respond with an error in the body
        kong.response.set_raw_body("You're not authorized. No JWT token was found")
      else 
        kong.response.set_raw_body("")
      end
    end
  end
  
  kong.log("LOG.body_filter: end\n")
end

-- return the created table, so that Kong can execute it
return JWTCheckerHandler
