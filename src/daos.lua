require("luacov")
local typedefs = require "kong.db.schema.typedefs" 

local tantem_canary_enabler_datastore = {
  primary_key = {"modulename"},
  name = "tantem_canary_enabler_datastore",

  fields = {
	  {id = typedefs.uuid},
	  {created_at = typedefs.auto_timestamp_s},
	  {hitrate = {type = "integer", required = true,},}, -- hitrate count
	  {modulename = {type = "string", required = true,},}, -- moduleName of deployment , Primary key of plugin
	  {key = {type = "string", required = false, unique = true,},}, -- a unique API key
  },
}

return {tantem_canary_enabler_datastore}
