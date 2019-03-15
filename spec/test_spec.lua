local access = require "../src/access"

describe ("unit test access to tantem-canary-enabler functions" , function ()
  setup(function()

-- Mocked Variables - Global
    _G.hostHeader = ""
    _G.ngx = {}
    _G.kong = {}
    _G.kong.request = {}
    _G.kong.req = {}
    _G.ngx.req = {}
    _G.ngx.var = {}
    _G.ngx.ctx = {}
    _G.ngx.ctx.router_matches = {}
    _G.ngx.ctx.router_matches.uri = 'start'
    _G.kong.db = {}
    _G.kong.db.tantem_canary_enabler_datastore = {}
    _G.ngx.re = {}
    _G.kong.service = {}
    _G.kong.service.request = {}

-- Mocked Functions
    function kong.db.tantem_canary_enabler_datastore:insert()
    local data = {hitrate = 1}
    return data,nil
    end

    function kong.db.tantem_canary_enabler_datastore:update()
    local data = {hitrate = 1}
    return data,nil
    end

    function ngx.req.get_headers()
        table = {}
        table["authorization"] = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UiLCJpYXQiOjE1MTYyMzkwMjIsIm1vZHVsZXMiOlsiSmVua2lucyIsIlRlc3RpbmciLCJNYXRsYWIiXX0.YqmlYg_nAfopQNzAxFeSA5qj7WHx0BRnPrPFAGKWvUQ"
    return table
    end

    function ngx.re.match(authorization_header,bearer)
        data = {}
        data[1] = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiSm9obiBEb2UiLCJpYXQiOjE1MTYyMzkwMjIsIm1vZHVsZXMiOlsiSmVua2lucyIsIlRlc3RpbmciLCJNYXRsYWIiXX0.YqmlYg_nAfopQNzAxFeSA5qj7WHx0BRnPrPFAGKWvUQ'
    return data,nil
    end

    function kong.request.get_path()
	requestPath = '/path'
    return requestPath
    end

    function kong.service.request.set_path(value)
        setPath = value
    end

    function kong.service.set_target(hostvalue , portvalue)
   	return hostvalue.portvalue
    end

    function kong.service.set_upstream(value)
    	setUpstream = value
    end
  end)

-- Test Cases

  it ("transform target - StrictEnforce: True -  UserBased", function()
    ngx.ctx.upstream_url = "https://localhost:3000/path/"
    local conf = {}
    conf.moduleName = 'Jenkins'
    conf.canaryHost = 'localhost'
    conf.canaryPort = '3001'
    conf.canaryPercentage = 30
    conf.canaryPath = '/to/canary'
    conf.userCanary = true
    conf.canaryUpstream = 'upstream-canary'
    conf.strictEnforce = true
    access.execute(conf)
    assert.equal("/to/canary/path",setPath)
    assert.equal("upstream-canary",setUpstream)
  end)


  it ("transform target - StrictEnforce: True - PercentageBased - Data Query: Present", function()

    function kong.db.tantem_canary_enabler_datastore:select()
    local data = {hitrate = 1}
    return data,nil 
    end

    ngx.ctx.upstream_url = "https://localhost:3000/path/"
    local conf = {}
    conf.moduleName = 'Benkins'
    conf.canaryHost = 'localhost'
    conf.canaryPort = '3001'
    conf.canaryPercentage = 30
    conf.canaryPath = '/to/canary'
    conf.userCanary = false
    conf.canaryUpstream = 'upstream-canary'
    conf.strictEnforce = true
    access.execute(conf)
    assert.equal("/to/canary/path",setPath)
    assert.equal("upstream-canary",setUpstream)
  end)

  it ("transform target - StrictEnforce: True - PercentageBased - Data Query: Absent", function()

    function kong.db.tantem_canary_enabler_datastore:select()
    return nil,nil 
    end

    ngx.ctx.upstream_url = "https://localhost:3000/path/"
    local conf = {}
    conf.moduleName = 'Benkins'
    conf.canaryHost = 'localhost'
    conf.canaryPort = '3001'
    conf.canaryPercentage = 30
    conf.canaryPath = '/to/canary'
    conf.userCanary = false
    conf.canaryUpstream = 'upstream-canary'
    conf.strictEnforce = true
    access.execute(conf)
    assert.equal("/to/canary/path",setPath)
    assert.equal("upstream-canary",setUpstream)
  end)

  it ("transform target - StrictEnforce: False - UserBased", function()
    ngx.ctx.upstream_url = "https://localhost:3000/path/"
    local conf = {}
    conf.moduleName = 'Benkins'
    conf.canaryHost = 'localhost'
    conf.canaryPort = '3001'
    conf.canaryPercentage = 30
    conf.canaryPath = '/to/canary'
    conf.userCanary = true
    conf.canaryUpstream = 'upstream-canary'
    conf.strictEnforce = false
    access.execute(conf)
    assert.equal("/to/canary/path",setPath)
    assert.equal("upstream-canary",setUpstream)
  end)
end)
