module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  BaseAccessory = require('./base')(env)

  class ButtonAccessory extends BaseAccessory

    constructor: (device) ->
      super(device, Service.Switch)

      button = device.config.buttons[0]

      reset = () =>
        @service.setCharacteristic(Characteristic.On, 0)

      @service.getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          if value is 1
            @handleVoidPromise(device.buttonPressed(button.id)
              .then( => setTimeout(reset, 250)), callback)
          else
            callback()
