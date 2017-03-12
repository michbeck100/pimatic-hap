module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  DefaultAccessory = require('./default')(env)

  class ButtonAccessory extends DefaultAccessory

    constructor: (device, buttonToTrigger) ->
      # this handling is needed in order to support pimatic devices
      # which need to be represented by mutiple homekit devices
      # as function overloading is not supportet in node
      if !buttonToTrigger?
        # buttonToTrigger was omitted in constructor call thus we need to call super
        # without additional parameters to propagate that they were not manipulated
        # basically this is legacy handling to support previous behaviour with
        # support for only one button
        super(device, Service.Switch)
        button = device.config.buttons[0]
      else
        #manipulate device name to reflect buttons-device + button name
        deviceName = "#{device.name} #{buttonToTrigger.text}"
        #manipulate device ID to allow multiple instances of device
        deviceId = device.id + buttonToTrigger.id

        super(device, Service.Switch, deviceId, deviceName)
        button = buttonToTrigger

      reset = () =>
        @service.updateCharacteristic(Characteristic.On, 0)

      @service.getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          if value is 1
            @handleVoidPromise(device.buttonPressed(button.id)
              .then( => setTimeout(reset, 250)), callback)
          else
            callback()
