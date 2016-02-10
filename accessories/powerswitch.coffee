module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  SwitchAccessory = require('./switch')(env)

  ##
  # PowerSwitch
  ##
  class PowerSwitchAccessory extends SwitchAccessory

    constructor: (device) ->
      super(device)

      service = @getServiceOverride(Service.Switch)

      @addService(service, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          promise = if value then device.turnOn() else device.turnOff()
          @handleVoidPromise(promise, callback)

      @getService(service)
        .getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getState(), callback, null)

      device.on 'state', (state) =>
        @getService(service)
          .setCharacteristic(Characteristic.On, state)
