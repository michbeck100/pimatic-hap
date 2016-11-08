module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  BaseAccessory = require('./base')(env)

  ##
  # TemperatureSensor
  ##
  class GenericAccessory extends BaseAccessory

    constructor: (device) ->
      super(device)

      if device.hasAttribute('temperature')
        @addService(Service.TemperatureSensor, device.name)
          .getCharacteristic(Characteristic.CurrentTemperature)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getTemperature(), callback, null)
          .props.minValue = -50

        device.on 'temperature', (temperature) =>
          @getService(Service.TemperatureSensor)
            .setCharacteristic(Characteristic.CurrentTemperature, temperature)

        @addBatteryStatus(device, @getService(Service.TemperatureSensor))

      # some devices also measure humidity
      if device.hasAttribute('humidity')
        @addService(Service.HumiditySensor, device.name)
        @getService(Service.HumiditySensor)
          .getCharacteristic(Characteristic.CurrentRelativeHumidity)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getHumidity(), callback, null)

        device.on 'humidity', (humidity) =>
          @getService(Service.HumiditySensor)
            .setCharacteristic(Characteristic.CurrentRelativeHumidity, humidity)

        @addBatteryStatus(device, @getService(Service.HumiditySensor))

    addBatteryStatus: (device, service) =>
      if device.hasAttribute('lowBattery')
        service
          .getCharacteristic(Characteristic.StatusLowBattery)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getLowBattery(), callback, @getBatteryStatus)

        device.on 'lowBattery', (state) =>
          service
            .setCharacteristic(Characteristic.StatusLowBattery, @getBatteryStatus(state))

    getBatteryStatus: (state) =>
      if state
        return Characteristic.StatusLowBattery.BATTERY_LEVEL_LOW
      else
        return Characteristic.StatusLowBattery.BATTERY_LEVEL_NORMAL
