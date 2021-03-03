module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  DimmerAccessory = require('./dimmer')(env)

  class WooxRGBWLightAccessory extends DimmerAccessory

    _hue = null

    constructor: (device) ->
      super(device)
      _hue = device._hue

      @service.getCharacteristic(Characteristic.Hue)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getHue(), callback, null)

      @service.getCharacteristic(Characteristic.Hue)
        .on 'set', (hue, callback) =>
          if hue is @_hue
            callback()
            return
          @_hue = hue
          @handleVoidPromise(device.changeHueTo(hue), callback)

      device.on 'hue', (hue) =>
        console.log("Hue received from Device: #{hue}")
        @service.updateCharacteristic(Characteristic.Hue, hue)
