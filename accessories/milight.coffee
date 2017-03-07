module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  DimmerAccessory = require('./dimmer')(env)

  class MilightAccessory extends DimmerAccessory

    _hue = null

    constructor: (device) ->
      super(device)
      _hue = device._hue

      @service.getCharacteristic(Characteristic.Hue)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getHue(), callback, @_getHueInDegree)

      @service.getCharacteristic(Characteristic.Hue)
        .on 'set', (value, callback) =>
          # value = 0 -> hue = 176
          hue = @getHueForMilight(value)
          if hue is @_hue
            callback()
            return
          @_hue = hue
          @handleVoidPromise(device.changeHueTo(hue), callback)

      device.on 'hue', (hue) =>
        @service.updateCharacteristic(Characteristic.Hue, @_getHueInDegree(hue))

    _getHueInDegree: (hue) =>
      return (Math.floor((256 + 176 - hue) * 360 / 256)) % 360

    _getHueForMilight: (degrees) =>
      return (256 + 176 - Math.floor(degrees / 360 * 255)) % 256
