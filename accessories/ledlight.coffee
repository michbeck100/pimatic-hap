module.exports = (env) ->

  Color = require 'color'
  Please = require 'pleasejs'

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  SwitchAccessory = require('./switch')(env)

  class LedLightAccessory extends SwitchAccessory

    _color: null

    constructor: (device) ->
      super(device)

      device.getColor().then( (rgb) =>
        @_color = if rgb == '' then Color("#FFFFFF") else Color(rgb)
      )

      @addService(Service.Lightbulb, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          if device.getState().power == value
            ## nothing changed
            callback()
            return
          if value
            @handleVoidPromise(device.turnOn(), callback)
          else
            @handleVoidPromise(device.turnOff(), callback)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getPower(), callback, null)

      device.on 'power', (state) =>
        @getService(Service.Lightbulb)
          .setCharacteristic(Characteristic.On, state == 'on')

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getBrightness(), callback, null)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on 'set', (value, callback) =>
          @handleVoidPromise(device.setBrightness(value), callback)

      device.on 'brightness', (brightness) =>
        @getService(Service.Lightbulb)
          .setCharacteristic(Characteristic.Brightness, brightness)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Hue)
        .on 'get', (callback) =>
          callback(null, @getHue())

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Hue)
        .on 'set', (value, callback) =>
          if value == @getHue()
            callback()
            return
          hex = Please.HSV_to_HEX(h: value, s: 1, v: 1)
          @handleVoidPromise(device.setColor(hex), callback)

      device.on 'color', (hexColor) =>
        @_color = if hexColor == '' then Color("#FFFFFF") else Color(hexColor)
        @getService(Service.Lightbulb)
          .setCharacteristic(Characteristic.Hue, @getHue())

    getHue: =>
      return @_color.hslArray()[0]

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
