module.exports = (env) ->

  convert = require 'color-convert'

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  DefaultAccessory = require('./default')(env)

  class LedLightAccessory extends DefaultAccessory

    # hsv value of current color
    _color: null

    constructor: (device) ->
      super(device, Service.Lightbulb)

      device.getColor().then( (rgb) =>
        @_color = convert.rgb.hsv(if rgb == '' then [255, 255, 255] else rgb)
      )

      @service.getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          if device.getState().power == value
            ## nothing changed
            callback()
            return
          if value
            @handleVoidPromise(device.turnOn(), callback)
          else
            @handleVoidPromise(device.turnOff(), callback)

      @service.getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getPower(), callback, null)

      device.on 'power', (state) =>
        @service.updateCharacteristic(Characteristic.On, state == 'on')

      @service.getCharacteristic(Characteristic.Brightness)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getBrightness(), callback, null)

      @service.getCharacteristic(Characteristic.Brightness)
        .on 'set', (value, callback) =>
          @_color[2] = value
          @handleVoidPromise(device.setBrightness(value), callback)

      device.on 'brightness', (brightness) =>
        @service.updateCharacteristic(Characteristic.Brightness, brightness)

      @service.getCharacteristic(Characteristic.Hue)
        .on 'get', (callback) =>
          callback(null, @getHue())

      @service.getCharacteristic(Characteristic.Hue)
        .on 'set', (value, callback) =>
          if value == @getHue()
            callback()
            return
          @_color[0] = value
          hex = convert.hsv.hex(@_color)
          @handleVoidPromise(device.setColor('#' + hex), callback)

      device.on 'color', (hexColor) =>
        @_color = convert.hex.hsv(if hexColor == '' then '#FFFFFF' else hexColor)
        @service
          .updateCharacteristic(Characteristic.Hue, @getHue())
          .updateCharacteristic(Characteristic.Saturation, @getSaturation())
          .updateCharacteristic(Characteristic.Brightness, @getBrightness())

      @service.getCharacteristic(Characteristic.Saturation)
        .on 'get', (callback) =>
          callback(null, @getSaturation())

      @service.getCharacteristic(Characteristic.Saturation)
        .on 'set', (value, callback) =>
          if value == @getSaturation()
            callback()
            return
          @_color[1] = value
          hex = convert.hsv.hex(@_color)
          @handleVoidPromise(device.setColor('#' + hex), callback)

    getHue: =>
      return @_color[0]

    getSaturation: =>
      return @_color[1]

    getBrightness: =>
      return @_color[2]

    # identify method toggles the light on and off two times
    identify: (device, paired, callback) =>
      delay = 500
      promise = device.getPower()
        .then( (state) =>
          device.turnOff().delay(delay)
          .then( => device.turnOn().delay(delay) )
          .then( => device.turnOff().delay(delay) )
          .then( => device.turnOn().delay(delay) )
          .then( =>
            # recover initial state
            device.turnOff().delay(delay) if not state
          )
        )
      @handleVoidPromise(promise, callback)
