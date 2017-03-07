module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  BaseAccessory = require('./base')(env)

  ##
  # TemperatureSensor
  ##
  class GenericAccessory extends BaseAccessory

    @supportedAttributes: ['temperature', 'humidity', 'co2']

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
            .updateCharacteristic(Characteristic.CurrentTemperature, temperature)

        @addBatteryStatus(device, @getService(Service.TemperatureSensor))
        @addRemoveListener(device, @getService(Service.TemperatureSensor))

      # some devices also measure humidity
      if device.hasAttribute('humidity')
        @addService(Service.HumiditySensor, device.name)
          .getCharacteristic(Characteristic.CurrentRelativeHumidity)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getHumidity(), callback, null)

        device.on 'humidity', (humidity) =>
          @getService(Service.HumiditySensor)
            .updateCharacteristic(Characteristic.CurrentRelativeHumidity, humidity)

        @addBatteryStatus(device, @getService(Service.HumiditySensor))
        @addRemoveListener(device, @getService(Service.HumiditySensor))

      if device.hasAttribute('co2')
        @addService(Service.CarbonDioxideSensor)
          .getCharacteristic(Characteristic.CarbonDioxideDetected)
          .on 'get', (callback) =>
            device.getCo2().then( (co2) => callback(null, @getCarbonDioxideDetected(co2)))

        @getService(Service.CarbonDioxideSensor)
          .getCharacteristic(Characteristic.CarbonDioxideLevel)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getCo2(), callback, null)

        device.on 'co2', (co2) =>
          @getService(Service.CarbonDioxideSensor)
            .updateCharacteristic(Characteristic.CarbonDioxideDetected,
              @getCarbonDioxideDetected(co2))
          @getService(Service.CarbonDioxideSensor)
            .updateCharacteristic(Characteristic.CarbonDioxideLevel, co2)

        @addRemoveListener(device, @getService(Service.CarbonDioxideSensor))


    addBatteryStatus: (device, service) =>
      if device.hasAttribute('lowBattery')
        service
          .getCharacteristic(Characteristic.StatusLowBattery)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getLowBattery(), callback, @getBatteryStatus)

        device.on 'lowBattery', (state) =>
          service
            .updateCharacteristic(Characteristic.StatusLowBattery, @getBatteryStatus(state))

    getBatteryStatus: (state) =>
      if state
        return Characteristic.StatusLowBattery.BATTERY_LEVEL_LOW
      return Characteristic.StatusLowBattery.BATTERY_LEVEL_NORMAL

    # http://www.raumluft.org/natuerliche-mechanische-lueftung/co2-als-lueftungsindikator/
    # a value of 1400 ppm should the maximum co2 level
    getCarbonDioxideDetected: (co2) ->
      if co2 > 1400
        return Characteristic.CarbonDioxideDetected.CO2_LEVELS_ABNORMAL
      return Characteristic.CarbonDioxideDetected.CO2_LEVELS_NORMAL

    addRemoveListener: (device, service) =>
      device.on 'remove', () =>
        env.logger.debug 'removing device ' + device.name
        @removeService(service)
