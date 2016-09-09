module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  DimmerAccessory = require('./dimmer')(env)

  class HueLightAccessory extends DimmerAccessory

    _hue = null
    _sat = null

    constructor: (device) ->
      super(device)
      _hue = device._hue
      _sat = device._sat

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Hue)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getHue(), callback, null)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Hue)
        .on 'set', (value, callback) =>
          if value is @_hue
            callback()
            return
          @_hue = value
          @handleVoidPromise(device.changeHueTo(value), callback)

      device.on 'hue', (hue) =>
        @getService(Service.Lightbulb)
          .setCharacteristic(Characteristic.Hue, hue)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Saturation)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getSat(), callback, null)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Saturation)
        .on 'set', (value, callback) =>
          if value == @_sat
            callback()
            return
          @_sat = value
          @handleVoidPromise(device.changeSatTo(value), callback)
