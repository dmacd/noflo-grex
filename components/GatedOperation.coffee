noflo = require 'noflo'
_ = require 'underscore'


exports.GatedOperation = (obj, config) ->



  #(obj, inports, outports, flush_action, finish_action) ->
  name = obj.constructor?.name
  inports = config.inports
  outports = config.outports
  flush_action = config.flush_action
  finish_action = config.finish_action

  # this function returns a function which can serve as a constructor of a component

  init_port_state = (p) ->
    # data event handlers
    if p.data is 'buffer'
      obj.port_states[k].data = []
    else
      obj.port_states[k].data = null

  # map port descriptors to port definitions...

  obj.inPorts = {}
  obj.port_states = {}
  for k,p of inports
    do (k,p) ->
      obj.inPorts[k]= new noflo.Port (p.type ? 'any')
      obj.port_states[k] =
        ready: false


      # initial port states
      init_port_state(p)


      # validate that data spec is correct:
      unless (p.data is 'buffer' or !(p.data?))
        msg = name+':GatedOperation: Error: spec for port ' + k + ' data was invalid'
        console.error msg
        throw new Error msg

      # data event handlers
      if p.data is 'buffer'
        obj.inPorts[k].on "data", (data) ->
          obj.port_states[k].data.push data
      else
        obj.inPorts[k].on "data", (data) ->
          obj.port_states[k].data = data

      # disconnect event handlers
      obj.inPorts[k].on "disconnect", ->
        obj.port_states[k].ready = true
        flush()

  obj.outPorts = {}
  for k,p of outports
    do (k,p) ->
      obj.outPorts[k] = new noflo.Port(p.type ? 'any')


  flush = ->
    # test ready states

    #console.log('GatedOperation: flush()')
    for k,p of obj.port_states
      #console.log('GatedOperation: port ', k, ' is ', (if p.ready then 'ready' else 'waiting'))
      return unless p.ready is true


    #console.log('GatedOperation: all ports ready, flush() proceeding...')

    # check number of packets is correct...
    #lengths = ((d) -> d.length) ps.data for k, ps of obj.port_states when inports[k].data is 'buffer'
    lengths = []
    for k,ps of obj.port_states
      if (inports[k].data is 'buffer')
        lengths.push ps.data.length

    for i in [0...lengths.length]
      if (lengths[i] != lengths[0])
        msg =  name+":Gated Operation: failed to receive equal numbers of data packets on all buffered ports. \n"
        + _.map(obj.port_states, (ps,k)-> '\t'+k + ':' +ps.data.length).join('\n')
        console.error msg
        throw new Error msg

    #console.log name+':GatedOperation: lengths', lengths
    #console.log 'outports:', outports


    if (lengths.length is 0)
      lengths = [1] # nothing was buffered, so we'll only be sending one packet in this case, so tell the slicing logic we have exactly one

    # open the output ports
    for k,p in outports
      obj.outPorts[k].connect()

    ###
    # slice in to data packets
    port_state = {}
    for i in [0...lengths[0]] # for each set of buffered packets
      #console.log '...with buffered packet index ', i
      for k,p of inports
        if p.data is 'buffer'
          port_state[k] = obj.port_states[k].data[i]
        else
          port_state[k] = obj.port_states[k].data

      # console.log 'invoking flush action with state', port_state
      # execute action -- may include sends on outports, whatever

      # need to at least expose exceptions here because noflo is ghey and swallows them then
      try
        flush_action(obj, port_state )
      catch e
        # TODO: route exceptions to an error port?
        console.error name+':GatedOperation:flush_action:', e
        return
    ###
    flush_slice = (i) ->
      console.log(name+'GatedOperation:flush_slice('+ i+')')
      unless i < lengths[0]
        finish()
        return

      # slice in to data packets
      port_state = {}

      #console.log '...with buffered packet index ', i
      for k,p of inports
        if p.data is 'buffer'
          port_state[k] = obj.port_states[k].data[i]
        else
          port_state[k] = obj.port_states[k].data

      # console.log 'invoking flush action with state', port_state
      # execute action -- may include sends on outports, whatever

      # need to at least expose exceptions here because noflo is ghey and swallows them then
      try
        flush_action(obj, port_state, () -> flush_slice(i+1) )
      catch e
      # TODO: route exceptions to an error port?
        console.error name+':GatedOperation:flush_action:', e
        return


    flush_slice(0)


  finish = ->

    if finish_action
      console.log name+':GatedOperation: finish action' #, obj
      try
        finish_action(obj)
        console.log name+':GatedOperation: finish action finished'

      catch e
        console.error name+':GatedOperation:finish_action:', e
        return


    console.log name+':GatedOperation: closing outports ' #, outports #, obj.outPorts)
    # close the output ports
    for k,p of outports
      console.log name+':GatedOperation: disconnect ', k #, p)
      obj.outPorts[k].disconnect()

    # reset state

    for k,p of inports
      init_port_state(p)


















# state member variables

# ... event handles

# data, disconnect, including flushing and ready behavior


# construct the flush action handler
# assumeds that flush_action = (port1val, port2val, ... ) =>


# to call a method on an object
###

class ExampleAddVertex extends noflo.Component

  inports =
    tx:   # port names will be taken from the key name here
      type: 'object'
      #flush: 'trigger' # can be 'trigger', 'wait', or 'optional'. 'wait' is default # not clear this is needed
      data: 'replace'  # either 'buffer' or 'replace'. whether data packets are buffered and provided to the flush action multiple times or not. replace is default
    data:
      type: 'string'
      #flush: 'wait'
      data: 'buffer'

  outports =
    tx:             # keys matching inport names will forward the same data object(s) to output
      type: 'object'
    vertex:
      type: 'object'
  #   result: true   # could maybe put the flush operation here so the mapping is totalsly specified ....


  constructor: ->
    general_gated_ctor this, inports, outports, (port_state) ->
      port_state.tx.addVertex(port_state.data)



###