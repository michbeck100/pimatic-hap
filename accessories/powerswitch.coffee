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

      @addService(Service.Switch, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          promise = if value then device.turnOn() else device.turnOff()
          @handleVoidPromise(promise, callback)

      @getService(Service.Switch)
        .getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getState(), callback, null)

      device.on 'state', (state) =>
        @getService(Service.Switch)
          .setCharacteristic(Characteristic.On, state)
