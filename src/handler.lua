require("luacov")
local BasePlugin = require "kong.plugins.base_plugin"
local access = require "kong.plugins.tantem-canary-enabler.access"

-- Extending base plugin to use base functions defined in base class
local TantemCanaryEnablerHandler = BasePlugin:extend()

-- setting up the new plugin handler
function TantemCanaryEnablerHandler:new()
  TantemCanaryEnablerHandler.super.new(self, "tantem-canary-enabler")
end

-- calling the main handler for Tantem Transformer
function TantemCanaryEnablerHandler:access(conf)
  TantemCanaryEnablerHandler.super.access(self)
  access.execute(conf)
end

TantemCanaryEnablerHandler.PRIORITY = 1004 --Plugin executes after JWT as per Kong Precedence -- change it to 10 if you want least precedence
TantemCanaryEnablerHandler.VERSION = "1.0.0"


return TantemCanaryEnablerHandler
