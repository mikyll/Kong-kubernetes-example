local MyACL = {}



-- Checks if the user has the required permissions for a given path
-- 
-- @path is a string representing the route of the request.
-- @user_permissions is an array of permissions obtained from the JWT in the
--    request header.
-- @acl is the Access Control List, i.e. a dictionary of permissions allowed
--    for specific paths..
function MyACL.check_permissions(path, user_permissions, acl)
  if not path or 
      not acl or type(acl) ~= 'table' or not acl[path] or 
      not user_permissions
  then
    return false
  end
  
  local required_permissions = acl[path]
  
  for _, up in ipairs(user_permissions)
  do
    for _, rp in ipairs(required_permissions)
    do
      -- Check permission
      if up == rp
      then
        return true
      end
    end
  end
  
  return false
end

-- Parse ACL and return true if it's valid
function MyACL.is_valid(acl)
  -- TODO

  return true
end

-- Returns a YAML representation of the ACL, passed as a table
--  Parameters:
--  @tbl, the ACL table object
--  @indent, a string for the indentation (can be nil)
function MyACL.table_to_yaml(tbl, indent)
  indent = indent or ""
  local yaml = ""
  
  for key, value in pairs(tbl)
  do
    yaml = yaml .. indent .. key .. ":\n"
    if type(value) == "table"
    then
      for _, item in ipairs(value)
      do
        yaml = yaml .. indent .. "  - " .. item .. "\n"
      end
    else
      yaml = yaml .. indent .. "  - " .. value .. "\n"
    end
  end
  
  return yaml
end

-- TEST (Utile per stampare una table/array)
function MyACL.dump(o)
  if type(o) == 'table'
  then
    local s = '{ '
    for k,v in pairs(o)
    do
      if type(k) ~= 'number'
      then
        k = '"'..k..'"'
      end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

return MyACL




--[[ Extra

-- List of available scopes
local scopes = {
  -- Base
  "admin",
  "guest",
  
  -- Dealer roles
  "sales_dealer_role",
  "service_dealer_role",
  
  -- Vendor roles
  "vendor_user",
  "digital_service_manager",
  
  -- Branch roles
  "branch_user",
  "branch_manager",
  
  -- Customer roles
  "manager_di_linea",
  "manager_manutenzione",
  "maintainer",
  "operator",
  "ticket_manager",
}

-- URL mapping
local acl = {
  ["/admin"] = {"admin"},
  ["/superuser"] = {"admin"},
  ["/root"] = {"admin"},
  
  ["/customer"] = {
    "manager_di_linea",
    "manager_manutenzione", 
    "maintainer", 
    "operator", 
    "ticket_manager", 
    "admin"
  },
  
  ["/operator"] = {
    "operator",
    "admin"
  },
  
  ["/ticket_manager"] = {
    "ticket_manager",
    "admin"
  },
}
--]]