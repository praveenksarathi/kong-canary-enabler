return {
  postgres = {
    up = [[
      CREATE TABLE IF NOT EXISTS tantem_canary_enabler_datastore(
        id uuid,
        hitRate number,
        key text UNIQUE,
        moduleName text,
        created_at timestamp without time zone default (CURRENT_TIMESTAMP(0) at time zone 'utc'),
        PRIMARY KEY (moduleName)
      );
      CREATE INDEX IF NOT EXISTS ON tantem_canary_enabler_datastore(moduleName);
    ]],
  },

  cassandra = {
    up =  [[
      CREATE TABLE IF NOT EXISTS tantem_canary_enabler_datastore(
        id uuid,
	    hitRate int,
	    moduleName text,
        key text,
        created_at timestamp,
        PRIMARY KEY (moduleName)
      );
      	
     ]],
  }
}


