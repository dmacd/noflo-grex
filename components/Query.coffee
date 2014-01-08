noflo = require 'noflo'

class Query extends noflo.Component
  description: "Evaluates gremlin query expression from a string (in grex syntax, refer to grex docs). The argument should represent a function of one argument ('g') that returns a promise. Query execution buffer and triggered by disconnects on query and db ports"

  constructor: ->
    @query_data = []
    @db = null

    @inPorts =
      db: new noflo.Port 'object'
      query: new noflo.Port 'string'

    @outPorts =
      out: new noflo.Port 'all'
      query: new noflo.Port 'function'
      error: new noflo.Port 'object'

    @inPorts.db.on 'data', (@db) =>

    @inPorts.query.on 'data', (query_data) =>
      @query_data.push query_data

    @inPorts.query.on 'disconnect', () =>
      @flush()

    @inPorts.db.on 'disconnect', () =>
      @flush()

  flush: () =>
    unless @query_data and @db
      return
    console.log('flush @qd: ', @query_data)
    @run_query qd for qd in @query_data
    @query_data = []


  run_query: (query_data) =>
    if typeof query_data is "function"
      query = query_data
    else
      try
        query = Function("g", query_data)
      catch error
        @error 'Error creating query function: ' + query_data + '\n' + JSON.stringify(error)
    if query
      try
      ##@f(true)   # WTF?!? YOU DIPSHIT
        if @outPorts.query.isAttached()
          @outPorts.query.connect()
          @outPorts.query.send @f
          @outPorts.query.disconnect()
      catch error
        @error 'Error evaluating function: ' + query_data + '\n' + JSON.stringify(error)

      unless @db
        @error 'Database not set at time query requested'
        return
      console.log('Query: compiled query function:', query)

      try

        #console.log(@db.V('name','biatch')) #.then((r)=>console.log r)
        #return
        (query(@db)).getData().then((r)=>
          @outPorts.out.connect()
          @outPorts.out.send r
          @outPorts.out.disconnect()
        , @error)
      catch e
        #console.log e
        @error e

  error: (msg) ->
    if @outPorts.error.isAttached()
      @outPorts.error.send new Error msg
      @outPorts.error.disconnect()
      return
    console.error('Query error:',msg);
    throw new Error msg

exports.getComponent = -> new Query
