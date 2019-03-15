require("luacov")
require("compat53")

local check_value = function (value)
  if((math.type(value)) ~= "integer") or (value < 0) or (value > 100) then
    return false,[[Input out of range. Percentage value between 1 and 100 expected]]
  end
end

local check_port = function (value)
  if ((math.type(value)) ~= "integer") or (value < 1) or (value > 65535) then
    return false,[[Please enter whole numbers for port value between 1 to 65535]]
  end
end

local check_IP = function (value)
  local chunks = {value:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")}
  if (value == nil) or (type(value) ~= "string") or (#chunks ~= 4) then
    return false ,[[Please enter a valid IPv4 Host]]
  end
  for _,v in pairs(chunks) do
    if (tonumber(v) < 0 or tonumber(v) > 255) then
    return false , [[Please enter a valid IPv4 Host]]
    end
  end
end

return {
  fields = {
    moduleName = {
      type = "string",
      required = true,
    },
    canaryHost = {
      type = "string",
      required = true,
      func = check_IP,
    },
    canaryPort = {
      type = "number",
      required = true,
      func = check_port,
     },
    canaryPath = {
      type = "string",
      required = false,
    },
    canaryPercentage = {
      type = "number",
      required = true,
      func = check_value,
     },
    userCanary = {
      type = "boolean",
      default = false,
      required = false,
    },
    canaryUpstream = {
      type = "string",
      required = false,
     },
    strictEnforce = {
      type = "boolean",
      default = false,
      required = false,
     },
  }
}
