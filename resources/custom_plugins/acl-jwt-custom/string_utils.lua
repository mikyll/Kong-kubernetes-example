local StringUtils = {}

-- This function removes the specified substring from a given string.
-- @param str: The original string.
-- @param substr: The substring to be removed.
-- @return: Returns the modified string with the substring removed.
function StringUtils.removeSubstring(str, substr)
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
function StringUtils.stringSplit(inputstr, sep)
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

return StringUtils