module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  SwitchAccessory = require('./switch')(env)

  ##
  # DimmerActuator
  ##
  class DimmerAccessory extends SwitchAccessory

    constructor: (device) ->
      super(device)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getDimlevel(), callback, null)

      device.on 'dimlevel', (dimlevel) =>
        @getService(Service.Lightbulb)
          .setCharacteristic(Characteristic.Brightness, dimlevel)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on 'set', (value, callback) =>
          if device._dimlevel is value
            callback()
            return
          @handleVoidPromise(device.changeDimlevelTo(value), callback)

    getDefaultService: =>
      return Service.Lightbulb
