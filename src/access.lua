require("luacov")

-- Dependancies LUA packages
local json = require "json"

-- Object
local TantemCanaryEnabler = {} -- Empty Table (acts as an object for current instance)

-- Base 64 decoder to decode JWT Payload
local function base64Decode(data)

  --Template of allowed charecters in Base64 Encoding, used to decode encoded data
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

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

-- Regex function to extract data part from incoming JWT
local function getJWTPayload(Key)
  local header, data , encodingFormat = string.match(Key, "(.*)%.(.*)%.(.*)") --Regex extractor, segregating header , data and encodingFormat from JWT Key
  if not data then
    return nil
  end
  if data and header and encodingFormat and #data >0 then
    return data
  end
end

-- Extractor function to extract Auth token from incoming requests
local function getToken()
  local authorization_header = tostring(ngx.req.get_headers()["authorization"])

  if authorization_header then
    local iterator, iterErr = ngx.re.match(authorization_header, "\\s*[Bb]earer\\s+(.+)")
    if not iterator then
      return nil, iterErr
    end
    if iterator and #iterator > 0 then
      return iterator[1]
    else
      return nil
    end
  else
  return nil
  end
end

-- Verify if requesting User is registered as a Canary user for the requested service
local function isCanaryUserRegisteredForService(serviceMap,conf)

  local isUserRegisteredForService = false
  local decodedServiceMap = json.decode(serviceMap)

  for k, v in pairs(decodedServiceMap) do
    if k:upper() == 'MODULES' then
      for key , values in pairs(v) do
        if values:upper() == conf.moduleName:upper() then
          isUserRegisteredForService = true
        end
      end
    end
  end

  return isUserRegisteredForService
end


-- Main handler to verify if the user is registed canary or not
local function isUserRegisteredForCanary(conf)
  local isUserRegistered

  local token = getToken() -- Get the JWT Authorization Key from Header
  if token ~= nil then
    local JWTPayload = getJWTPayload(token) -- Decode Auth key to extract payload Key
    if (JWTPayload ~= nil) then
      local decodedPayload = base64Decode(JWTPayload) -- Extract Key data
      isUserRegistered = isCanaryUserRegisteredForService(decodedPayload,conf) -- Check if Module available for canary
    end
  end
  return isUserRegistered
end


-- Main handler to verify if the request is for canary or production under strict distribution

local function strictDistribution(conf)
if (conf.canaryHost) and (conf.canaryPort) then
	if (ngx.req.get_headers()['authorization'] ~= nil) and (isUserRegisteredForCanary(conf) == true) then
		return true
	elseif conf.canaryPercentage and (conf.userCanary ~= true) then
		local hits = 11 -- fallback to normal version
		local data, err = kong.db.tantem_canary_enabler_datastore:select({modulename = conf.moduleName}) -- Lookup in the datastore
			if err then
			error(err) -- caught by kong.cachnsformer_datastore and logged
			end
			if not data then
				local newData , newerr = kong.db.tantem_canary_enabler_datastore:insert({
					hitrate = 1,
					modulename = conf.moduleName
				})
				if newerr then
					error(err) -- caught by kong.cachnsformer_datastore and logged
				end
			hits = newData.hitrate ;
			end

			if data then
				local insertTable = {}
			if data.hitrate >= 10 then
				insertTable.hitrate = 1;
			else
				insertTable.hitrate = data.hitrate + 1;
			end
				insertTable.modulename = data.modulename;
				insertTable.id = data.id;
				local primaryKey = {}
				primaryKey.modulename = data.modulename;

				local updateData , updateErr = kong.db.tantem_canary_enabler_datastore:update(primaryKey,insertTable)
				if updateErr then
				error(err)
				end
			hits = updateData.hitrate ;
			end

		local probability = math.floor((((conf.canaryPercentage/100))*10)+0.5)
			if (hits <= probability) then
				return true
			else
				return false
			end

	else
		return false
	end

else
	return false
end
end

-- Set Seed for math.random
math.randomseed(os.time())

local function randomChance(chance)
  assert(chance >= 0 and chance <= 1)
  return chance >= math.random()
end

local function isCanarySelected(percent)
  local iscanarySelected
  -- Sample across 1000 tries
  for count=0,999 do
    if(randomChance(percent/100)) then
      iscanarySelected = true
    else
      iscanarySelected = false
    end
  end
  return iscanarySelected
end

-- Verify if the request has authorization header and that the plugin is configured for canary
local function isUserBasedCanaryRequest(conf)
  local isRequestCanary = false
  -- Check if the canary Upstream URL is available
  -- By default and as a fallback , the request will always go to production
  if((ngx.req.get_headers()['authorization'] ~= nil) and
    (conf.canaryHost and conf.canaryPort and conf.userCanary)) then
    isRequestCanary = true
  end
  return isRequestCanary
end

-- Main handler to verify if the request is for canary or production under pseudoRandomDistribution
local function pseudoRandomDistribution(conf)
  local isCanaryRequest = true
  if(conf.canaryHost and conf.canaryPort) then
    -- Check for User Based Canary Routing
    if(isUserBasedCanaryRequest(conf) and isUserRegisteredForCanary(conf)) then
      isCanaryRequest = true
    -- Check for % based Canary Routing
    elseif(conf.canaryPercentage and (conf.userCanary ~= true)) then
      isCanaryRequest = isCanarySelected(conf.canaryPercentage)
    end
  end
  return isCanaryRequest
end


-- host Transform handler
local function transform_target(conf)
  local requestPath = kong.request.get_path()
  local requestRoute = ngx.ctx.router_matches.uri
  local replacementPath
  local setHost
  local setPort
  local setUpstream

  if (conf.strictEnforce) then
    block = {
      isCanaryRouteNeeded = strictDistribution
    }
  else
    block = {
      isCanaryRouteNeeded = pseudoRandomDistribution
    }
  end

  if (block.isCanaryRouteNeeded(conf) == true) then
    if conf.canaryPath then
      replacementPath = conf.canaryPath .. (requestPath:gsub(requestRoute,""))
    end
    setHost = conf.canaryHost
    setPort = conf.canaryPort
    setUpstream = conf.canaryUpstream
  end

  if (setHost ~= nil) and (setPort ~= nil) then
    if (replacementPath) then
      kong.service.request.set_path(replacementPath)
    end
      kong.service.set_target(setHost,setPort)
    if (setUpstream ~= nil) then
      kong.service.set_upstream(setUpstream)
    end
  end
end

function TantemCanaryEnabler.execute(conf)
  -- Order of execution
  transform_target(conf) --[[Enable it to transform request path]]

end

return TantemCanaryEnabler
