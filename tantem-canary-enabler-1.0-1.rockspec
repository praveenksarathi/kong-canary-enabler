package = "tantem-canary-enabler"
version = "1.0-1"

-- The plugin version is 1.0 and the trailing "-1" represents rockspec version 1 , this rockspec version is to be updated when this Rockspec file gets changed/updated

source = {
  url = "https://gitlab.tools.in.pan-net.eu/LAAS/delivery-aricent-rest-code.git"
}

description = {
  summary = "A KONG plugin to facilitate user based and percentage based canary routing",
  license = ""
}

dependencies = {
  "lua >= 5.1",
  "lua-cjson",
  "luajson",
  "compat53",
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.tantem-canary-enabler.handler"] = "src/handler.lua",
    ["kong.plugins.tantem-canary-enabler.access"] = "src/access.lua",
    ["kong.plugins.tantem-canary-enabler.daos"] = "src/daos.lua",
    ["kong.plugins.tantem-canary-enabler.migrations.000_base_tantem_canary_enabler"] = "src/migrations/000_base_tantem_canary_enabler.lua",
    ["kong.plugins.tantem-canary-enabler.migrations.init"] = "src/migrations/init.lua",
    ["kong.plugins.tantem-canary-enabler.schema"] = "src/schema.lua"
  }
}
