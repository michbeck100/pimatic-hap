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

      @service.getCharacteristic(Characteristic.Hue)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getHue(), callback, @getHueInDegree)

      @service.getCharacteristic(Characteristic.Hue)
        .on 'set', (value, callback) =>
          hue = value / 360 * 100
          if hue is @_hue
            callback()
            return
          @_hue = hue
          @handleVoidPromise(device.changeHueTo(hue), callback)

      device.on 'hue', (hue) =>
        @service.updateCharacteristic(Characteristic.Hue, @getHueInDegree(hue))

      @service.getCharacteristic(Characteristic.Saturation)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getSat(), callback, null)

      device.on 'sat', (sat) =>
        @service.updateCharacteristic(Characteristic.Saturation, sat)

      @service.getCharacteristic(Characteristic.Saturation)
        .on 'set', (value, callback) =>
          if value == @_sat
            callback()
            return
          @_sat = value
          @handleVoidPromise(device.changeSatTo(value), callback)

    getHueInDegree: (hue) =>
      return hue / 100 * 360
