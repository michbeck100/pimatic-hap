module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  BaseAccessory = require('./base')(env)

  class ButtonAccessory extends BaseAccessory

    constructor: (device) ->
      super(device)

      button = device.config.buttons[0]

      reset = () =>
        @getService(Service.Switch)
          .setCharacteristic(Characteristic.On, 0)

      @addService(Service.Switch, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          if value is 1
            @handleVoidPromise(device.buttonPressed(button.id).then( => setTimeout(reset, 250)), callback)
          else
            callback()
