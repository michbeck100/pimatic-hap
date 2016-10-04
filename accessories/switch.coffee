module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  BaseAccessory = require('./base')(env)

  # base class for switch actuators
  class SwitchAccessory extends BaseAccessory

    _state = null

    constructor: (device) ->
      super(device)

      service = @getServiceOverride()
      @addService(service, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          #check if state is already available for device
          @_state = device._state
          env.logger.debug "Current state of #{device.name} is: #{@_state}"
          if @_state != null
            if value is 1 then value = true
            if value is 0 then value = false
            if value is @_state
              env.logger.debug 'value ' + value + ' equals current state of ' +
                device.name + '. Not switching.'
              callback()
              return
            env.logger.debug 'switching device ' + device.name + ' to ' + value
            @_state = value
            promise = if value then device.turnOn() else device.turnOff()
            @handleVoidPromise(promise, callback)
          else
            #if we don't have a state yet we can not properly determine whether to switch or not
            env.logger.debug "Device #{device.name} state not initialized yet, 
            ignoring state change"
            callback()
            return

      @getService(service)
        .getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getState(), callback, null)

      device.on 'state', (state) =>
        @getService(service)
          .setCharacteristic(Characteristic.On, state)

    # default identify method on switches turns the switch on and off two times
    identify: (device, paired, callback) =>
      # make sure it's off, then turn on and off twice
      promise = device.getState()
        .then( (state) =>
          device.turnOff()
          .then( => device.turnOn() )
          .then( => device.turnOff() )
          .then( => device.turnOn() )
          .then( =>
            # recover initial state
            device.turnOff() if not state
          )
        )
      @handleVoidPromise(promise, callback)
