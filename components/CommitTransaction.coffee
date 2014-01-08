# HACK: since I havent found the proper way to do browser build yet
unless noflo.isBrowser()
  gRex = require "grex"


noflo = require "noflo"


class CommitTransaction extends noflo.Component
  description: "Commits transa"

  constructor: ->
    @tx = null
    # Register ports
    @inPorts =
      tx: new noflo.Port "object"

    @outPorts =
      out: new noflo.Port()
      error: new noflo.Port()

    @inPorts.tx.on "data", (@tx) =>

    @inPorts.tx.on "disconnect", () =>
      console.log('CommitTx: disconnect on tx recieved');
      ###try
        @tx.commit((err, res) =>
          console.log err, res
        )
      catch e
        console.log('caught: ', e)###

      @tx.commit().then((result) =>
        @outPorts.out.send result
        @outPorts.out.disconnect()
      , (err) =>
        if (@outPorts.error.isAttached())
          @outPorts.error.send err
          @outPorts.error.disconnect()
        else
          throw new Error err
      )

exports.getComponent = -> new CommitTransaction()