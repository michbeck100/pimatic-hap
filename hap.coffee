
module.exports = (env) =>

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'
  crypto = env.require 'crypto'
  path = require 'path'

  Color = require 'color'

  hap = require 'hap-nodejs'
  Bridge = hap.Bridge
  Accessory = hap.Accessory
  Service = hap.Service
  Characteristic = hap.Characteristic
  uuid = require ('hap-nodejs/lib/util/uuid')

  class HapPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      env.logger.info("Starting homekit bridge")

      hap.init(path.resolve @framework.maindir, '../../hap-database')

      bridge = new Bridge(@config.name, uuid.generate(@config.name))

      bridge.on 'identify', (paired, callback) =>
        env.logger.debug(@config.name + " identify")
        callback()

      @framework.on 'deviceAdded', (device) =>
        accessory = @createAccessoryFromTemplate(device)

        if accessory?
          bridge.addBridgedAccessory(accessory)
          env.logger.debug("successfully added device " + device.name)

      @framework.once "after init", =>
        # publish homekit bridge
        env.logger.debug("publishing homekit bridge on port " + @config.port)
        env.logger.debug("pincode is: " + @config.pincode)

        bridge.publish({
          username: @generateUniqueUsername(bridge.displayName),
          port: @config.port,
          pincode: @config.pincode,
          category: Accessory.Categories.OTHER
        })

    generateUniqueUsername: (name) =>
      shasum = crypto.createHash('sha1')
      shasum.update(name)
      hash = shasum.digest('hex')

      return "" +
          hash[0] + hash[1] + ':' +
          hash[2] + hash[3] + ':' +
          hash[4] + hash[5] + ':' +
          hash[6] + hash[7] + ':' +
          hash[8] + hash[9] + ':' +
          hash[10] + hash[11]

    createAccessoryFromTemplate: (device) =>
      return switch device.template
        when 'dimmer' then new DimmerAccessory(device)
        when 'switch' then new SwitchAccessory(device)
        when 'shutter' then new ShutterAccessory(device)
        when 'temperature' then new TemperatureAccessory(device)
        when 'contact' then new ContactAccessory(device)
        when 'thermostat' then new ThermostatAccessory(device)
        when 'led-light' then new LedLightAccessory(device)
        else
          env.logger.debug("unsupported device type: " + device.constructor.name)
          null

  plugin = new HapPlugin()

  # base class for all homekit accessories in pimatic
  class DeviceAccessory extends Accessory

    constructor: (device) ->
      serialNumber = uuid.generate('pimatic-hap:accessories:' + device.id)
      super(device.name, serialNumber)

      @getService(Service.AccessoryInformation)
        .setCharacteristic(Characteristic.Manufacturer, "Pimatic")
        .setCharacteristic(Characteristic.Model, "Rev-1")
        .setCharacteristic(Characteristic.SerialNumber, serialNumber);
      @on 'identify', (paired, callback) =>
        @identify(device, paired, callback)

    ## default identify method just calls callback
    identify: (device, paired, callback) =>
      callback()

    ## calls promise, then callback, and handles errors
    handleVoidPromise: (promise, callback) =>
      promise
        .then( => callback() )
        .catch( (error) => callback(error) )
        .done()

    handleReturnPromise: (promise, callback, converter) =>
      promise
        .then( (value) =>
          if converter != null
            value = converter(value)
          callback(null, value)
        )
        .catch( (error) => callback(error, null) )
        .done()

  # base class for switch actuators
  class SwitchAccessory extends DeviceAccessory

    constructor: (device) ->
      super(device)

    # default identify method on switches turns the switch on and off two times
    identify: (device, paired, callback) =>
      # make sure it's off, then turn on and off twice
      promise = device.getState()
        .then( (state) =>
          device.turnOff()
          .then( => device.turnOn() )
          .then( => device.turnOff() )
          .then( => device.turnOn() )
          .then( =>
            # recover initial state
            device.turnOff() if not state
          )
        )
      @handleVoidPromise(promise, callback)

  ##
  # PowerSwitch
  ##
  class PowerSwitchAccessory extends SwitchAccessory

    constructor: (device) ->
      super(device)

      @addService(Service.Switch, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          if device._state == value
            callback()
            return
          @handleVoidPromise(device.changeStateTo(value), callback)

      @getService(Service.Switch)
        .getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getState(), callback, null)

      device.on 'state', (state) =>
        @getService(Service.Switch)
          .setCharacteristic(Characteristic.On, state)


  ##
  # DimmerActuator
  ##
  class DimmerAccessory extends SwitchAccessory

    constructor: (device) ->
      super(device)

      @addService(Service.Lightbulb, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          if device._state == value
            callback()
            return
          promise = null
          if value
            promise = device.turnOn()
          else
            promise = device.turnOff()
          @handleVoidPromise(promise, callback)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getState(), callback, null)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getDimlevel(), callback, null)

      device.on 'dimlevel', (dimlevel) =>
        @getService(Service.Lightbulb)
          .setCharacteristic(Characteristic.Brightness, dimlevel)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on 'set', (value, callback) =>
          if device._dimlevel == value
            callback()
            return
          @handleVoidPromise(device.changeDimlevelTo(value), callback)

  ##
  # ShutterController
  #
  # currently shutter is using Service.LockMechanism because Service.Window uses percentages
  # for moving the shutter which is not supported by ShutterController devices
  class ShutterAccessory extends DeviceAccessory

    constructor: (device) ->
      super(device)

      @addService(Service.LockMechanism, device.name)
        .getCharacteristic(Characteristic.LockTargetState)
        .on 'set', (value, callback) =>
          promise = null
          if value == Characteristic.LockTargetState.UNSECURED
            promise = device.moveUp()
          else if value == Characteristic.LockTargetState.SECURED
            promise = device.moveDown()
          if (promise != null)
            @handleVoidPromise(promise, callback)

      @getService(Service.LockMechanism)
        .getCharacteristic(Characteristic.LockTargetState)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getPosition(), callback, @getLockCurrentState)

      # opposite of target position getter
      @getService(Service.LockMechanism)
        .getCharacteristic(Characteristic.LockCurrentState)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getPosition(), callback, @getLockCurrentState)

      device.on 'position', (position) =>
        @getService(Service.LockMechanism)
          .setCharacteristic(Characteristic.LockCurrentState, @getLockCurrentState(position))

    getLockCurrentState: (position) =>
            if position == 'up'
              return Characteristic.LockCurrentState.UNSECURED
            else if position == "down"
              return Characteristic.LockCurrentState.SECURED
            else
              # stopped somewhere in between
              return Characteristic.LockCurrentState.UNKNOWN

  ##
  # ContactSensor
  ##
  class ContactAccessory extends DeviceAccessory

    constructor: (device) ->
      super(device)

      @addService(Service.ContactSensor, device.name)
        .getCharacteristic(Characteristic.ContactSensorState)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getContact(), callback, @getContactSensorState)

      device.on 'contact', (state) =>
        @getService(Service.ContactSensor)
          .setCharacteristic(Characteristic.ContactSensorState, @getContactSensorState(state))

    getContactSensorState: (state) =>
      if state
        return Characteristic.ContactSensorState.CONTACT_DETECTED
      else
        return Characteristic.ContactSensorState.CONTACT_NOT_DETECTED

  ##
  # TemperatureSensor
  ##
  class TemperatureAccessory extends DeviceAccessory

    constructor: (device) ->
      super(device)

      @addService(Service.TemperatureSensor, device.name)
        .getCharacteristic(Characteristic.CurrentTemperature)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getTemperature(), callback, null)

      device.on 'temperature', (temperature) =>
        @getService(Service.TemperatureSensor)
          .setCharacteristic(Characteristic.CurrentTemperature, temperature)

  ##
  # HeatingThermostat
  ##
  class ThermostatAccessory extends DeviceAccessory

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
            .setCharacteristic(Characteristic.TargetHeatingCoolingState, Characteristic.TargetHeatingCoolingState.AUTO)

    setTemperatureTo: (temp) =>
      if @_temperature is temp then return
      @_temperature = temp
      @getService(Service.Thermostat)
        .setCharacteristic(Characteristic.CurrentTemperature, temp)

  class LedLightAccessory extends DeviceAccessory

    _color: null

    constructor: (device) ->
      super(device)

      device.getColor().then( (rgb) =>
        @_color = if rgb == '' then Color("#FFFFFF") else Color(rgb)
      )

      @addService(Service.Lightbulb, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          if device.getState().power == value
            ## nothing changed
            callback()
            return
          if value
            @handleVoidPromise(device.turnOn(), callback)
          else
            @handleVoidPromise(device.turnOff(), callback)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getPower(), callback, null)

      device.on 'power', (state) =>
        @getService(Service.Lightbulb)
          .setCharacteristic(Characteristic.On, state == 'on')

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on 'get', (callback) =>
          @handleReturnPromise(device.getBrightness(), callback, null)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on 'set', (value, callback) =>
          @handleVoidPromise(device.setBrightness(value), callback)

      device.on 'brightness', (brightness) =>
        @getService(Service.Lightbulb)
          .setCharacteristic(Characteristic.Brightness, brightness)

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Hue)
        .on 'get', (callback) =>
          callback(null, @getHue())

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Hue)
        .on 'set', (value, callback) =>
          if value == @getHue()
            callback()
            return
          @_color.hue(value)
          @handleVoidPromise(device.setColor(@_color.hexString()), callback)

      device.on 'color', (hexColor) =>
        @_color = if hexColor == '' then Color("#FFFFFF") else Color(hexColor)
        @getService(Service.Lightbulb)
          .setCharacteristic(Characteristic.Hue, @getHue())

    getHue: =>
      return @_color.hslArray()[0]

  return plugin
