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
          mode =
            switch value
              when Characteristic.TargetHeatingCoolingState.AUTO then "auto"
              when Characteristic.TargetHeatingCoolingState.OFF then "manu"
              when Characteristic.TargetHeatingCoolingState.HEAT then "boost"
              when Characteristic.TargetHeatingCoolingState.COOL then "manu"
          device.changeModeTo(mode)
          callback()

      device.on 'mode', (mode) =>
        coolingstate =
          switch mode
            when "auto" then Characteristic.TargetHeatingCoolingState.AUTO
            when "manu" then Characteristic.TargetHeatingCoolingState.OFF
            when "boost" then Characteristic.TargetHeatingCoolingState.HEAT
            else throw new Error("unsupported mode " + mode)
        @service.updateCharacteristic(Characteristic.TargetHeatingCoolingState, coolingstate)

    setTemperatureTo: (temp) =>
      if @_temperature is temp then return
      @_temperature = temp
      @service.updateCharacteristic(Characteristic.CurrentTemperature, temp)
