





class InvokeMethod extends noflo.Component

  inports =
    in:   # port names will be taken from the key name here
      type: 'object'
    data:
      type: 'string'
      data: 'buffer'

  outports =
    out:             # maybe todo: keys matching inport names will forward the same data object(s) to output
      type: 'object'
    vertex:
      type: 'object'
   #   result: true   # could maybe put the flush operation here so the mapping is totalsly specified ....


  constructor: ->
    general_gated_ctor this, inports, outports, (port_state) ->
      port_state.tx.addVertex(port_state.data)



