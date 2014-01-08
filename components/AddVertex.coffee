# HACK: since I havent found the proper way to do browser build yet
unless noflo.isBrowser()
  gRex = require "grex"


noflo = require "noflo"
go = require './GatedOperation'


class AddVertex extends noflo.Component
  description: "Calls tx.AddVertex(data) for each data packet; gated by TX. "

  constructor: ->
    go.GatedOperation this,
      inports:
        tx: { type: 'object' }
        data: { type: 'object', data: 'buffer' }
      outports:
        tx: { type: 'object'}
        vertex: { type: 'object'}
      flush_action: (self, port_state, next) ->
        console.log('AddVertex: flush', port_state)
        vertex = port_state.tx.addVertex(port_state.data)
        #vertex = port_state.tx.addVertex port_state.data
        console.log 'AddVertex vertex is', vertex
        console.log 'AddVertex vertex outport attached?', self.outPorts.vertex.isAttached()
        self.outPorts.vertex.send vertex
        next()

      finish_action: (self) ->
        console.log('AddVertex: finish')
        self.outPorts.tx.send self.port_states.tx.data # UUUGH VERRRRY IMPORTANT .data here

exports.getComponent = -> new AddVertex()


###
class AddVertex extends noflo.Component
  description: "Creates vertices with data packets in to vertices, forwarding the updated tx object on when the data stream disconnects and all vertices have been created. Waits for tx to arrive, buffers data packets."

  constructor: ->
    @vertex_data = []
    @tx = null

    # Register ports
    @inPorts =
      tx: new noflo.Port "object"
      data: new noflo.Port "object"

    @outPorts =
      tx: new noflo.Port()
      vertex: new noflo.Port()

    @inPorts.data.on "data", (data) =>
      @vertex_data.push(data)

    @inPorts.tx.on "data", (@tx) =>

    @inPorts.data.on "disconnect", () =>
      @flush()

    @inPorts.tx.on "disconnect", ()=>
      @flush()

  flush: =>
    unless @tx and @vertex_data
      return

    console.log('vertex data:',@vertex_data)
    vertices = (@tx.addVertex v for v in @vertex_data)
    console.log('vertices:',vertices)
    @vertex_data = []
    @outPorts.vertex.send v for v in vertices
    @outPorts.vertex.disconnect()
    @outPorts.tx.send @tx
    console.log('addvertex: sending tx disco')
    @outPorts.tx.disconnect()
    console.log('addvertex: tx disco sent')
    @tx = null

###

