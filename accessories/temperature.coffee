module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  BaseAccessory = require('./base')(env)

  ##
  # TemperatureSensor
  ##
  class TemperatureAccessory extends BaseAccessory

    constructor: (device) ->
      super(device)

      @addService(Service.TemperatureSensor, device.name)
        .getCharacteristic(Characteristic.CurrentTemperature)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getTemperature(), callback, null)
        .props.minValue = -50

      device.on 'temperature', (temperature) =>
        @getService(Service.TemperatureSensor)
          .setCharacteristic(Characteristic.CurrentTemperature, temperature)

      # some devices also measure humidity
      if device.hasAttribute('humidity')
        @addService(Service.HumiditySensor, device.name)
          .getCharacteristic(Characteristic.CurrentRelativeHumidity)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getHumidity(), callback, null)

        device.on 'humidity', (humidity) =>
          @getService(Service.HumiditySensor)
            .setCharacteristic(Characteristic.CurrentRelativeHumidity, humidity)
