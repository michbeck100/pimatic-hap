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
      super(device, Service.TemperatureSensor)

      if device.hasAttribute('temperature')
        @service.getCharacteristic(Characteristic.CurrentTemperature)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getTemperature(), callback, null)
          .props.minValue = -50

        device.on 'temperature', (temperature) =>
          @service.setCharacteristic(Characteristic.CurrentTemperature, temperature)

        @addBatteryStatus(device, Service.TemperatureSensor)

      # some devices also measure humidity
      if device.hasAttribute('humidity')
        @addService(Service.HumiditySensor, device.name)
          .getCharacteristic(Characteristic.CurrentRelativeHumidity)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getHumidity(), callback, null)

        device.on 'humidity', (humidity) =>
          @getService(Service.HumiditySensor)
            .setCharacteristic(Characteristic.CurrentRelativeHumidity, humidity)

        @addBatteryStatus(device, Service.HumiditySensor)

    addBatteryStatus: (device, service) =>
      if device.hasAttribute('lowBattery')
        @getService(service)
          .getCharacteristic(Characteristic.StatusLowBattery)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getLowBattery(), callback, @getBatteryStatus)

        device.on 'lowBattery', (state) =>
          @getService(service)
            .setCharacteristic(Characteristic.StatusLowBattery, @getBatteryStatus(state))

    getBatteryStatus: (state) =>
      if state
        return Characteristic.StatusLowBattery.BATTERY_LEVEL_LOW
      else
        return Characteristic.StatusLowBattery.BATTERY_LEVEL_NORMAL
