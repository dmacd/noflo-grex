noflo = require 'noflo'

go = require './GatedOperation'

class GetOrAddVertex extends noflo.Component

  inports =
    graph: { type: 'object' }
    tx: { type: 'object' }
    data: { type: 'object', data: 'buffer' }
    matchkey1: { type: 'string'  }  # key and value used to determine whether this vertex already exists
    #matchvalue1: { type: 'string', data: 'buffer' }
    matchkey2: { type: 'string'  }  # key and value used to determine whether this vertex already exists
    #matchvalue2: { type: 'string', data: 'buffer' }

  outports =
    tx:
      type: 'object'
    vertex:
      type: 'object'


  constructor: ->
    go.GatedOperation this,
      inports: inports
      outports: outports,
      flush_action: (self, port_state, next) ->     # flush action

        # first look up if the vertex exists already
        console.log 'GetOrAddVertex: port_state:', port_state

        ###try
          console.log 'GetOrAddVertex: query promise:', port_state.graph.V().has(port_state.matchkey1, port_state.data[port_state.matchkey1]).has(port_state.matchkey2, port_state.data[port_state.matchkey2]).getData().then (r) ->
            console.log('GetOrAddVertex: ', r)
        catch e
          console.log e
        ###

        port_state.graph.V().has(port_state.matchkey1, port_state.data[port_state.matchkey1]).has(port_state.matchkey2, port_state.data[port_state.matchkey2]).getData().then (r) ->
          try
            console.log("getoraddvertex", r)
            vertices = r.results;

            vertex = null
            if r.results.length > 0
              vertex = r.results[0]
              console.log 'GetOrAddVertex: FOUND vertex:', vertex
            else

              # TODO: if r turns up nothing...doesnt exist
              vertex = port_state.tx.addVertex(port_state.data)
              console.log 'GetOrAddVertex: ADDED vertex:', vertex

            self.outPorts.vertex.send vertex
            next()
          catch e
            msg = 'GetOrAddvertex: Exception: ' + e
            console.error(msg)
            throw new Error msg

      finish_action: (self) ->                   # finish action
        self.outPorts.tx.send self.port_states.tx.data



exports.getComponent = -> new GetOrAddVertex
