module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  DefaultAccessory = require('./default')(env)

  # base class for switch actuators
  class SwitchAccessory extends DefaultAccessory

    _state = null

    supportedServiceOverrides: {
      "Lightbulb": Service.Lightbulb
    }

    constructor: (device) ->
      super(device)
      @_state = device._state

      @service.getCharacteristic(Characteristic.On)
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

      @service.getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          state = device.getState(),
          return unless state?
          @handleReturnPromise(state, callback, null)

      device.on 'state', (state) =>
        @_state = state
        @service.updateCharacteristic(Characteristic.On, state)
