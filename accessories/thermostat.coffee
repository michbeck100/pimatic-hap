module.exports = (env) ->

  hap = require 'hap-nodejs'
  Service = hap.Service
  Characteristic = hap.Characteristic

  BaseAccessory = require('./base')(env)

  ##
  # HeatingThermostat
  ##
  class ThermostatAccessory extends BaseAccessory

    _temperature: null

    constructor: (device) ->
      super(device)

      @addService(Service.Thermostat, device.name)
        .getCharacteristic(Characteristic.TemperatureDisplayUnits)
        .on 'get', (callback) =>
          callback(null, Characteristic.TemperatureDisplayUnits.CELSIUS)

      @getService(Service.Thermostat)
        .getCharacteristic(Characteristic.CurrentTemperature)
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

      @getService(Service.Thermostat)
        .getCharacteristic(Characteristic.TargetTemperature)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getTemperatureSetpoint(), callback, null)

      @getService(Service.Thermostat)
        .getCharacteristic(Characteristic.TargetTemperature)
        .on 'set', (value, callback) =>
          device.changeTemperatureTo(value)
          # this may be the only chance to get a nearly accurate temperature
          @setTemperatureTo(value)
          callback()

      device.on 'temperatureSetpoint', (target) =>
        @getService(Service.Thermostat)
          .setCharacteristic(Characteristic.TargetTemperature, target)

      @getService(Service.Thermostat)
        .getCharacteristic(Characteristic.CurrentHeatingCoolingState)
        .on 'get', (callback) =>
          # don't know what cooling states are supposed to be,
          # for now always return Characteristic.CurrentHeatingCoolingState.HEAT
          callback(null, Characteristic.CurrentHeatingCoolingState.HEAT)

      @getService(Service.Thermostat)
        .getCharacteristic(Characteristic.TargetHeatingCoolingState)
        .on 'get', (callback) =>
          # don't know what cooling states are supposed to be,
          # for now always return Characteristic.TargetHeatingCoolingState.AUTO
          callback(null, Characteristic.TargetHeatingCoolingState.AUTO)

      @getService(Service.Thermostat)
        .getCharacteristic(Characteristic.TargetHeatingCoolingState)
        .on 'set', (value, callback) =>
          # just mode auto is known
          # the other modes don't match
          if value == Characteristic.TargetHeatingCoolingState.AUTO
            device.changeModeTo("auto")
          callback()

      device.on 'mode', (mode) =>
        if mode == "auto"
          @getService(Service.Thermostat)
            .setCharacteristic(Characteristic.TargetHeatingCoolingState,
            Characteristic.TargetHeatingCoolingState.AUTO)

    setTemperatureTo: (temp) =>
      if @_temperature is temp then return
      @_temperature = temp
      @getService(Service.Thermostat)
        .setCharacteristic(Characteristic.CurrentTemperature, temp)
