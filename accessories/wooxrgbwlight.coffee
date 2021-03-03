module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  SwitchAccessory = require('./switch')(env)

  class WooxRGBWLightAccessory extends SwitchAccessory
    # hsb value of current color
    _color: {
      h: null
      s: null
      b: null
    }
    _dimlevel = 0
    

    constructor: (device) ->
      super(device)
      device.getHsb().then( (hsb) => 
        @_color.h = hsb[0]
        @_color.s = hsb[1]
        @_color.b = hsb[2]
      )
      device.getDimlevel().then( (level) => @_dimlevel = level)
      
      @service.getCharacteristic(Characteristic.Hue)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getHue(), callback, null)

      @service.getCharacteristic(Characteristic.Hue)
        .on 'set', (hue, callback) =>
          if hue is @_color.h
            callback()
            return
          @_color.h = hue
          @handleVoidPromise(device.changeHueTo(hue), callback)

      device.on 'hue', (hue) =>
        console.log("Hue received from Device: #{hue}")
        @service.updateCharacteristic(Characteristic.Hue, hue)

      @service.getCharacteristic(Characteristic.Saturation)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getSaturation(), callback, null)

      @service.getCharacteristic(Characteristic.Saturation)
        .on 'set', (saturation, callback) =>
          if saturation is @_color.s
            callback()
            return
          @_color.s = saturation
          @handleVoidPromise(device.changeSaturationTo(saturation), callback)

      device.on 'saturation', (saturation) =>
        console.log("Saturation received from Device: #{saturation}")
        @service.updateCharacteristic(Characteristic.Saturation, saturation)
      
      @service.getCharacteristic(Characteristic.Brightness)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getBrightness(), callback, null)

      @service.getCharacteristic(Characteristic.Brightness)
        .on 'set', (brightness, callback) =>
          if brightness is @_color.b
            callback()
            return
          
          @_color.b = brightness
          @_dimlevel = brightness
          #if @_color.h is 0 && @_color.s is 0 && @_color.b is 100
          if brightness is 1
            @handleVoidPromise(device.changeDimlevelTo(brightness), callback)
          
          else
            @handleVoidPromise(device.changeBrightnessTo(brightness), callback)

      device.on 'brightness', (brightness) =>
        console.log("Brightness received from Device: #{brightness}")
        @service.updateCharacteristic(Characteristic.Brightness, brightness)
      
      device.on 'dimlevel', (dimlevel) =>
        console.log("Dimlevel received from Device: #{dimlevel}")
        @service.updateCharacteristic(Characteristic.Brightness, dimlevel)
        @service.updateCharacteristic(Characteristic.Saturation, 0)
        @service.updateCharacteristic(Characteristic.Hue, 0)
        

