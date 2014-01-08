noflo = require "noflo"

# HACK: since I havent found the proper way to do browser build yet
unless noflo.isBrowser()
  gRex = require "grex"

#console.log("grex client loaded")

class GrexClient extends noflo.Component
  description: "Provides a gremlin client to a specified rexster graph server"

  constructor: ->

    @host = null
    @port = null
    @graph = null
    # Register ports
    @inPorts =
      host: new noflo.Port "string"
      port: new noflo.Port "number"
      graph: new noflo.Port "string"
      connect: new noflo.Port "bang"

    @outPorts =
      db: new noflo.Port()
      error: new noflo.Port()

    @inPorts.host.on "data", (@host) =>

    @inPorts.port.on "data", (@port) =>

    @inPorts.graph.on "data", (@graph) =>

    @inPorts.connect.on "disconnect", () =>
      options =
        'graph': @graph
        'host': @host
        'port': @port

      gRex.connect(options)
        .then((graphDB) =>

          ###try
            graphDB.V().getData().then ((result) => console.log('ok:', result)), ((err) => console.log('error:',err))
          catch e
            console.error e

          return###

          @outPorts.db.connect()
          #console.log('sending graph', graphDB)
          @outPorts.db.send graphDB
          #console.log('db port disconnecting')
          @outPorts.db.disconnect()
          #console.log('db port disconnect sent')
        )
        .fail((err)=>      # is it even possible for this to be called?
          if (@outPorts.error.isAttached())
            @outPorts.error.connect()
            @outPorts.error.send err
            @outPorts.error.disconnect()
          else
            throw new Error err
        );

      ###gRex.connect fucking_gay_object, (err, graphDB) ->
        console.log err, graphDB
        if (err)
          @outPorts.error.connect()
          @outPorts.error.send err
          @outPorts.error.disconnect()
        else
          @outPorts.db.connect()
          @outPorts.db.send graphDB
          @outPorts.db.disconnect()

           ###

exports.getComponent = -> new GrexClient()




###
     g = graphDB
     tx = g.begin()
     tx.addVertex({ name: 'biatch'})
     tx.commit().then((r)=> console.log('commit result:', r))
###