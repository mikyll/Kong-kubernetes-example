--[[
===============================================================================

ACL JWT Custom Plugin

Plugin per implementare funzionalità di autorizzazione tramite ACL su Kong,
con possibilita' di impostare ruoli multipli (il plugin ufficiale supporta solo
singoli ruoli, mentre per ConsumerGroup serve una licenza enterprise).

Funzionamento:
- carica una ACL di permessi necessari per ciascun path;
- quando riceve una richiesta, stacca il token JWT dall'header e lo parsa;
- se il JWT contiene un field 'scopes' con dei permessi, e uno di questi permessi
    è associato (nella ACL di configurazione) al path richiesto, la richiesta
    viene propagata al servizio;
- se il JWT non contiene le autorizzazioni necessarie, la richiesta viene bloccata
    e Kong risponde direttamente con un 401 o 403, senza propagare la richiesta al
    servizio.

-------------------------------------------------------------------------------

Come funziona un JWT [...]

===============================================================================
--]]

-- Personal libs, loaded from current directory
local Encoding = require "kong.plugins.acl-jwt-custom.encoding"
local StringUtils = require "kong.plugins.acl-jwt-custom.string_utils"
local MyACL = require "kong.plugins.acl-jwt-custom.my_acl"

-- Other libs, loaded from /usr/local/share/lua/5.1/kong/tools/
local Cjson = require "cjson"

-- Kong Custom Plugin Handler
local ACL_JWT_Handler = {}

ACL_JWT_Handler.PRIORITY = 909 -- Run after rate-limiting
ACL_JWT_Handler.VERSION = "1.0.0"
ACL_JWT_Handler.NAME = "acl-jwt-custom"

local function find_plugin_with_key(data, keySubstring)
  for _, entry in ipairs(data) do
    if entry["__key__"]:find(keySubstring, 1, true) then
      return entry
    end
  end
  return nil
end

local function get_scopes_str(scopes)
  local scopes_str = ""
  for i, scope in ipairs(scopes)
  do
    scopes_str = scopes_str .. "- " .. scope
    if i < #scopes
    then
      scopes_str = scopes_str .. "\n"
    end
  end
  return scopes_str
end

-- TESTING FUNCTION
local function test_mock(scopes, acl)
  local path = "/admin"
  if MyACL.check_permissions(path, scopes, acl)
  then
    kong.log("LOG.header_filter:\nACCESS GRANTED: ", path, "\n\n")
  else
    kong.log("LOG.header_filter:\nACCESS DENIED: ", path, "\n\n")
  end
  
  path = "/customer"
  if MyACL.check_permissions(path, scopes, acl)
  then
    kong.log("LOG.header_filter:\nACCESS GRANTED: ", path, "\n\n")
  else
    print("LOG.header_filter:\nACCESS DENIED: ", path, "\n\n")
  end
end


--======================================================================
-- KONG PLUGIN LOGIC 
--======================================================================

ACL_JWT_Handler.ACCESS_GRANTED = false

-- Called when a new configuration is loaded for this plugin
function ACL_JWT_Handler:configure(configs)
  -- kong.log("LOG.configure: start\n\n")
  
  -- Loop over all the configurations (it's an array containing
  --  a configuration dictionary for each plugin)
  local acl_config = find_plugin_with_key(configs, "plugins:" .. self.NAME)
  
  -- Check if we found a config for our ACL plugin
  if not acl_config
  then
    kong.log("LOG.configure:\nACL config is missing in the array\n\n")
  end
  kong.log("LOG.configure:\nACL:\n", MyACL.table_to_yaml(acl_config.acl), "\n\n")

  -- kong.log("LOG.configure: end\n\n")
end

-- Docs: [...]
function ACL_JWT_Handler:header_filter(config)
  if config.verbose then kong.log("LOG.header_filter: start\n\n") end
  
  -- No ACL was passed in plugin configuration
  if not config.acl
  then 
    kong.log("LOG.header_filter: ACL config not found.\n\n")
    return kong.response.error(401, "ACL is missing")
  end
  
  -- Find 'Authorization' header
  local authHeaderValue = kong.request.get_header('authorization')
  if not authHeaderValue
  then
    kong.log("LOG.header_filter: authorization header not found.\n\n")
    return kong.response.error(401, "Authorization header missing.")
  end
  if config.verbose then kong.log("LOG.header_filter: authorization header found.\n\n") end
  
  -- Find 'Bearer' authorization schema
  if not string.find(string.lower(authHeaderValue), "bearer")
  then
    kong.log("LOG.header_filter: Bearer authorization schema missing.\n\n")
    return kong.response.error(401, "Authorization header schema must be 'Bearer'. Current schema: " .. authHeaderValue)
  end
  if config.verbose then kong.log("LOG.header_filter: Bearer authorization schema\n\n") end
  
  -- Get token
  local token = removeSubstring(authHeaderValue, "Bearer ")
  if config.verbose then kong.log("LOG.header_filter:\nFull encoded token: ", token, "\n\n") end
  
  -- Count the token parts
  local tokenParts = stringSplit(token, ".")
  if #tokenParts ~= 3
  then
    kong.log("LOG.header_filter:\nThe token is missing a part (num parts: ", #tokenParts, ").\n\n")
    return kong.response.error(403, "The token is missing a part (num parts: " .. tostring(#tokenParts) .. ").")
  end
  
  -- Get token parts (decode JWT)
  local tokenHeader = Encoding.decodeBase64(tokenParts[1])
  local tokenPayload = Encoding.decodeBase64(tokenParts[2])
  local tokenSignature = tokenParts[3]
  if config.verbose then kong.log("LOG.header_filter:\nToken parts:\nHeader: ", 
    tokenHeader, "\nPayload: ", tokenPayload, "\nSignature: ", tokenSignature, "\n\n") end
  
  -- Check JWT validity (find 'typ:jwt'): claims, signature and expiration time
  local tokenType = tokenHeader:gsub("%s+", "")
  if not string.find(string.lower(tokenType), '"typ":"jwt"')
  then
    kong.log("LOG.header_filter:\nWrong token type: ", tokenType, "\n\n")
    return kong.response.error(403, "Wrong token type: " .. tokenType)
  end
  if config.verbose then kong.log("LOG.header_filter:\nCorrect token type: ", tokenType, "\n\n") end
  
  -- Find key "scopes" in JWT payload (JSON)
  local payload = Cjson.decode(tokenPayload)
  if not payload.scopes
  then
    kong.log("LOG.header_filter:\nField 'scopes' not found.\n\n")
    return kong.response.error(403, "No field 'scopes' was found in JWT.")
  end
  
  -- Log scopes in a fancy way
  local scopes_str = get_scopes_str(payload.scopes)
  if config.verbose then kong.log("LOG.header_filter:\n", #payload.scopes, " scopes found in request JWT:\n", scopes_str, "\n\n") end
  
  -- Retrieve the request sub-path
  local path_str = kong.request.get_path()
  local second_slash_index = path_str:find("/", path_str:find("/") + 1) -- Find the index of the second "/"
  local path = "/"
  if second_slash_index
  then
    path = path_str:sub(second_slash_index) -- Get the substring starting from the second "/"
  end
  if config.verbose then kong.log("LOG.header_filter:\nForwarded path: ", kong.request.get_forwarded_path(), "\nPath: ", kong.request.get_path(), "\nRaw Path: ", kong.request.get_raw_path(), "\n\n") end
  
  -- Check permissions based on configuration ACL
  if MyACL.check_permissions(path, payload.scopes, config.acl)
  then
    kong.log("LOG.header_filter:\nACCESS GRANTED: ", path, "\n\n")
    self.ACCESS_GRANTED = true
  else
    kong.log("LOG.header_filter:\nACCESS DENIED: ", path, "\n\n")
    self.ACCESS_GRANTED = false
    return kong.response.error(401, "Unauthorized for path: " .. path)
  end
  
  -- TEST
  -- test_mock(payload.scopes, config.acl)
  
  if config.verbose then kong.log("LOG.header_filter: end\n\n") end
end

-- return the created table, so that Kong can execute it
return ACL_JWT_Handler
