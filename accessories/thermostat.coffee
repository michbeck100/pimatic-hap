module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  DefaultAccessory = require('./default')(env)

  ##
  # HeatingThermostat
  ##
  class ThermostatAccessory extends DefaultAccessory

    _temperature: null

    constructor: (device) ->
      super(device, Service.Thermostat)

      @service.getCharacteristic(Characteristic.TemperatureDisplayUnits)
        .on 'get', (callback) =>
          callback(null, Characteristic.TemperatureDisplayUnits.CELSIUS)

      @service.getCharacteristic(Characteristic.CurrentTemperature)
        .on 'get', (callback) =>
          if @_temperature == null
            device.getTemperatureSetpoint().then( (temp) =>
              @_temperature = temp
              callback(null, @_temperature)
            )
          else
            callback(null, @_temperature)

      # some devices report the current temperature
      device.on 'temperature', (temp) =>
        @setTemperatureTo(temp)

      @service.getCharacteristic(Characteristic.TargetTemperature)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getTemperatureSetpoint(), callback, null)

      @service.getCharacteristic(Characteristic.TargetTemperature)
        .on 'set', (value, callback) =>
          device.changeTemperatureTo(value)
          # this may be the only chance to get a nearly accurate temperature
          @setTemperatureTo(value)
          callback()

      device.on 'temperatureSetpoint', (target) =>
        @service.updateCharacteristic(Characteristic.TargetTemperature, target)

      @service.getCharacteristic(Characteristic.CurrentHeatingCoolingState)
        .on 'get', (callback) =>
          # don't know what cooling states are supposed to be,
          # for now always return Characteristic.CurrentHeatingCoolingState.HEAT
          callback(null, Characteristic.CurrentHeatingCoolingState.HEAT)

      @service.getCharacteristic(Characteristic.TargetHeatingCoolingState)
        .on 'get', (callback) =>
          # don't know what cooling states are supposed to be,
          # for now always return Characteristic.TargetHeatingCoolingState.AUTO
          callback(null, Characteristic.TargetHeatingCoolingState.AUTO)

      @service.getCharacteristic(Characteristic.TargetHeatingCoolingState)
        .on 'set', (value, callback) =>
          # just mode auto is known
          # the other modes don't match
          if value == Characteristic.TargetHeatingCoolingState.AUTO
            device.changeModeTo("auto")
          callback()

      device.on 'mode', (mode) =>
        if mode == "auto"
          @service.updateCharacteristic(Characteristic.TargetHeatingCoolingState,
            Characteristic.TargetHeatingCoolingState.AUTO)

    setTemperatureTo: (temp) =>
      if @_temperature is temp then return
      @_temperature = temp
      @service.updateCharacteristic(Characteristic.CurrentTemperature, temp)
