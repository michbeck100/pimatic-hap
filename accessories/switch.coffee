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
      @_state = device._state

      service = @getServiceOverride()
      @addService(service, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          # HomeKit uses 0 or 1, must be converted to bool
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

      @getService(service)
        .getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getState(), callback, null)

      device.on 'state', (state) =>
        @_state = state
        @getService(service)
          .setCharacteristic(Characteristic.On, state)
          
