# HACK: since I havent found the proper way to do browser build yet
unless noflo.isBrowser()
  gRex = require "grex"


noflo = require "noflo"

go = require './GatedOperation'



class AddEdge extends noflo.Component

  inports =
    tx: { type: 'object' }
    type: { type: 'string' }
    from: { type: 'object', data: 'buffer' }
    to: { type: 'object', data: 'buffer' }
    data: { type: 'object', data: 'buffer' }

  outports =
    tx:
      type: 'object'
    edge:
      type: 'object'


  constructor: ->
    go.GatedOperation this,
      inports: inports
      outports: outports
      flush_action: (self, port_state, next) ->   # flush action

        # first look up if the vertex exists already
        console.log 'AddEdge: port_state:', port_state

        ###try
          console.log 'GetOrAddVertex: query promise:', port_state.graph.V().has(port_state.matchkey1, port_state.data[port_state.matchkey1]).has(port_state.matchkey2, port_state.data[port_state.matchkey2]).getData().then (r) ->
            console.log('GetOrAddVertex: ', r)
        catch e
          console.log e
        ###

        edge = port_state.tx.addEdge(port_state.from, port_state.to, port_state.type, port_state.data)
        console.log('edge is: ',edge);
        self.outPorts.edge.send edge
        next()

      finish_action: (self) ->             # finish action
        self.outPorts.tx.send self.port_states.tx.data


exports.getComponent = -> new AddEdge()

###
class AddEdge extends noflo.Component
  description: "Creates edges with data packets, forwarding the updated tx object on when the data stream disconnects and all vertices have been created. Waits for tx to arrive, buffers vertex (from, to) and data packets. Edge type is set once and not buffered over subsequent connections"

  constructor: ->
    @edge_data = []
    @from = []
    @type = null
    @to = []
    @tx = null

    @ready =
      from: false
      to: false
      edge_data: false

    # Register ports
    @inPorts =
      tx: new noflo.Port "object"
      from: new noflo.Port "vertex"
      to: new noflo.Port "vertex"
      type: new noflo.Port "string"
      data: new noflo.Port "object"

    @outPorts =
      tx: new noflo.Port()
      edge: new noflo.Port()

    # edge data
    @inPorts.data.on "data", (data) =>
      @edge_data.push(data)

    @inPorts.data.on "disconnect", () =>
      @ready.edge_data = true
      @flush()

    # transaction object
    @inPorts.tx.on "data", (@tx) =>

    @inPorts.tx.on "disconnect", ()=>
      @flush()

    # type string
    @inPorts.type.on "data", (@type) =>

    @inPorts.type.on "disconnect", () =>
      @flush()

    # from vertex
    @inPorts.from.on "data", (data) =>
      @from.push data

    @inPorts.from.on "disconnect", () =>
      @ready.from = true
      @flush()

    # to vertex
    @inPorts.to.on "data", (data) =>
      @to.push data

    @inPorts.to.on "disconnect", () =>
      @ready.to = true
      @flush()

  flush: =>
    unless @tx and @type and @ready.from and @ready.to and @ready.edge_data
      return


    # it is an error if there are equal numbers of each of from, to, and edge data

    if @from.length != @to.length or @from.length != @edge_data.length
      throw new Error "Incorrect number of data packets received for edge creation"

    # flush everything that can be flushed

    @outPorts.edge.connect();
    @outPorts.tx.connect();

    for i in [0...@from.length]
      do (i) =>
        @flush_edge(@from[i], @to[i], @edge_data[i])

    @outPorts.edge.disconnect();

    @outPorts.tx.send @tx
    console.log('addedge: sending tx disco')
    @outPorts.tx.disconnect()
    console.log('addedge: tx disco sent')

    # reset state
    @tx = null
    @type = null
    @edge_data = []
    @from = []
    @to = []
    @ready =
      from: false
      to: false
      edge_data: false

  flush_edge: (from, to, edge_data) =>
    console.log('from:',from, 'to:', to, 'data:', edge_data)
    edge = @tx.addEdge(from, to, @type, edge_data)
    console.log('edge is: ',edge);
    @outPorts.edge.send edge

###
