module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  BaseAccessory = require('./base')(env)

  ##
  # TemperatureSensor
  ##
  class GenericAccessory extends BaseAccessory

    @supportedAttributes: ['temperature', 'humidity', 'co2', 'presence', 'contact', 'water', 'carbon', 'lux', 'fire']

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

      if device.hasAttribute('presence')
        @addService(Service.MotionSensor, device.name)
          .getCharacteristic(Characteristic.MotionDetected)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getPresence(), callback, null)

        device.on 'presence', (motionDetected) =>
          @getService(Service.MotionSensor)
            .updateCharacteristic(Characteristic.MotionDetected, motionDetected)

        @addBatteryStatus(device, @getService(Service.MotionSensor))
        @addRemoveListener(device, @getService(Service.MotionSensor))

      if device.hasAttribute('contact')
        @addService(Service.ContactSensor, device.name)
          .getCharacteristic(Characteristic.ContactSensorState)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getContact(), callback, @getContactSensorState)
        device.on 'contact', (state) =>
          @getService(Service.ContactSensor)
            .updateCharacteristic(Characteristic.ContactSensorState, @getContactSensorState(state))

        @addBatteryStatus(device, @getService(Service.ContactSensor))
        @addRemoveListener(device, @getService(Service.ContactSensor))

      if device.hasAttribute('water')
        @addService(Service.LeakSensor, device.name)
          .getCharacteristic(Characteristic.LeakDetected)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getWater(), callback, @getWaterState)
        device.on 'water', (state) =>
          @getService(Service.LeakSensor)
            .updateCharacteristic(Characteristic.LeakDetected, @getWaterState(state))

        @addBatteryStatus(device, @getService(Service.LeakSensor))
        @addRemoveListener(device, @getService(Service.LeakSensor))

      if device.hasAttribute('carbon')
        @addService(Service.CarbonMonoxideSensor, device.name)
          .getCharacteristic(Characteristic.CarbonMonoxideDetected)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getCarbon(), callback, @getCarbonState)
        device.on 'carbon', (state) =>
          @getService(Service.CarbonMonoxideSensor)
            .updateCharacteristic(Characteristic.CarbonMonoxideDetected, @getCarbonState(state))

        @addBatteryStatus(device, @getService(Service.CarbonMonoxideSensor))
        @addRemoveListener(device, @getService(Service.CarbonMonoxideSensor))

      if device.hasAttribute('lux')
        @addService(Service.LightSensor, device.name)
          .getCharacteristic(Characteristic.CurrentAmbientLightLevel)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getLux(), callback, null)
        device.on 'lux', (state) =>
          @getService(Service.LightSensor)
            .updateCharacteristic(Characteristic.CurrentAmbientLightLevel, state)

        @addBatteryStatus(device, @getService(Service.LightSensor))
        @addRemoveListener(device, @getService(Service.LightSensor))

      if device.hasAttribute('fire')
        @addService(Service.SmokeSensor, device.name)
          .getCharacteristic(Characteristic.SmokeDetected)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getFire(), callback, @getSmokeState)
        device.on 'fire', (state) =>
          @getService(Service.SmokeSensor)
            .updateCharacteristic(Characteristic.SmokeDetected, @getSmokeState(state))

        @addBatteryStatus(device, @getService(Service.SmokeSensor))
        @addRemoveListener(device, @getService(Service.SmokeSensor))

    addBatteryStatus: (device, service) =>
      if device.hasAttribute('lowBattery')
        service
          .getCharacteristic(Characteristic.StatusLowBattery)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getLowBattery(), callback, @getBatteryStatus)

        device.on 'lowBattery', (state) =>
          service
            .updateCharacteristic(Characteristic.StatusLowBattery, @getBatteryStatus(state))
      if device.hasAttribute('battery')
        service
          .getCharacteristic(Characteristic.StatusLowBattery)
          .on 'get', (callback) =>
            @handleReturnPromise(device.getBattery(), callback, @isBatteryLow)

        device.on 'battery', (value) =>
          service
            .updateCharacteristic(Characteristic.StatusLowBattery, @isBatteryLow(value))

    # lowBattery if battery value is < 20%
    isBatteryLow: (value) =>
      if value < 20
        return Characteristic.StatusLowBattery.BATTERY_LEVEL_LOW
      else
        return Characteristic.StatusLowBattery.BATTERY_LEVEL_NORMAL

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

    getContactSensorState: (state) =>
      if state
        return Characteristic.ContactSensorState.CONTACT_DETECTED
      else
        return Characteristic.ContactSensorState.CONTACT_NOT_DETECTED

    getWaterState: (state) =>
      if state
        return Characteristic.LeakDetected.LEAK_DETECTED
      else
        return Characteristic.LeakDetected.LEAK_NOT_DETECTED

    getCarbonState: (state) =>
      if state
        return Characteristic.CarbonMonoxideDetected.CO_LEVELS_ABNORMAL
      else
        return Characteristic.CarbonMonoxideDetected.CO_LEVELS_NORMAL

    getSmokeState: (state) =>
      if state
        return Characteristic.SmokeDetected.SMOKE_DETECTED
      else
        return Characteristic.SmokeDetected.SMOKE_NOT_DETECTED

    addRemoveListener: (device, service) =>
      device.on 'remove', () =>
        env.logger.debug 'removing device ' + device.name
        @removeService(service)
