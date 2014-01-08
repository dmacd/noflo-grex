noflo = require "noflo"
gRex = require "grex"

class BeginTransaction extends noflo.Component
  description: "Provides a gremlin client to a specified rexster graph server"

  constructor: ->
    @db = null
    # Register ports
    @inPorts =
      db: new noflo.Port "object"

    @outPorts =
      tx: new noflo.Port()

    @inPorts.db.on "data", (@db) =>
      console.log('begintx got db')

    @inPorts.db.on "disconnect", () =>
      console.log('db.begin:')

      tx = @db.begin()
      console.log('db.begin:',tx)
      @outPorts.tx.send tx
      @outPorts.tx.disconnect()


exports.getComponent = -> new BeginTransaction()