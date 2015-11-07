
module.exports = (env) =>

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  crypto = env.require 'crypto'

  hap = require 'hap-nodejs'
  Bridge = hap.Bridge
  Accessory = hap.Accessory
  Service = hap.Service
  Characteristic = hap.Characteristic
  uuid = require ('hap-nodejs/lib/util/uuid')

  class HapPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      env.logger.info("Starting homekit bridge")
      hap.init()

      bridge = new Bridge(@config.name, uuid.generate(@config.name))

      bridge.on 'identify', (paired, callback) =>
        env.logger.debug(@config.name + " identify")
        callback()

      @framework.on 'deviceAdded', (device) =>
        env.logger.debug("trying to add device " + device.name)
        accessory: null
        if device instanceof env.devices.DimmerActuator
          accessory = new DimmerAccessory(device)
        else if device instanceof env.devices.SwitchActuator
          accessory = new PowerSwitchAccessory(device)
        else if device instanceof env.devices.ShutterController
          accessory = new ShutterAccessory(device)
        else if device instanceof env.devices.TemperatureSensor
          accessory = new TemperatureAccessory(device)
        else
          env.logger.debug("unsupported device type " + device.constructor.name)
        if accessory?
          bridge.addBridgedAccessory(accessory)
          env.logger.debug("successfully added device " + device.name)

      @framework.once "after init", =>
        # publish homekit bridge
        env.logger.debug("publishing homekit bridge on port " + @config.port)
        env.logger.debug("pincode is: " + @config.pincode)

        bridge.publish({
          username: this.generateUniqueUsername(bridge.displayName),
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

  plugin = new HapPlugin()

  # base class for all homekit accessories in pimatic
  class DeviceAccessory extends Accessory

    constructor: (device) =>
      serialNumber = uuid.generate('pimatic-hap:accessories:' + device.id)
      super(device.name, serialNumber)

      @getService(Service.AccessoryInformation)
        .setCharacteristic(Characteristic.Manufacturer, "Pimatic")
        .setCharacteristic(Characteristic.Model, "Rev-1")
        .setCharacteristic(Characteristic.SerialNumber, serialNumber);
      @on 'identify', (paired, callback) =>
        this.identify(device, paired, callback)

    ## default identify method just logs and calls callback
    identify: (device, paired, callback) =>
      env.logger.debug("identify " + device.name)
      callback()

  # base class for switch actuators
  class SwitchAccessory extends DeviceAccessory

    constructor: (device) =>
      super(device)

    # default identify method on switches turns the switch on and off two times
    identify: (device, paired, callback) =>
      env.logger.debug("blinking " + device.name + " twice for identification")
      # make sure it's off, then turn on and off twice
      device.getState().then( (state) =>
        device.turnOff().then(
          device.turnOn().then(
            device.turnOff().then(
              device.turnOn().then(
                # recover initial state
                if !state
                  device.turnOff().then(callback())
                else
                  callback()
              )
            )
          )
        )
      )

  ##
  # PowerSwitch
  ##
  class PowerSwitchAccessory extends SwitchAccessory

    constructor: (device) =>
      super(device)

      @addService(Service.Switch, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          env.logger.debug("changing state of " + this.displayName + " to " + value)
          device.changeStateTo(value).then( callback() )

      @getService(Service.Switch)
        .getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          device.getState().then( (state) => callback(null, state) )

  ##
  # DimmerActuator
  ##
  class DimmerAccessory extends SwitchAccessory

    constructor: (device) =>
      super(device)

      @addService(Service.Lightbulb, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          env.logger.debug("changing state to " + value)
          if value
            device.turnOn().then( callback() )
          else
            device.turnOff().then( callback() )

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          device.getState().then( (state) => callback(null, state) )

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on 'get', (callback) =>
          device.getDimlevel().then( (dimlevel) => callback(null, dimlevel) )

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on 'set', (value, callback) =>
          env.logger.debug("changing dimLevel to " + value)
          device.changeDimlevelTo(value).then( callback() )

  ##
  # ShutterController
  #
  # currently shutter is using Service.LockMechanism because Service.Window uses percentages
  # for moving the shutter which is not supported by ShutterController devices
  class ShutterAccessory extends DeviceAccessory

    constructor: (device) =>
      super(device)

      @addService(Service.LockMechanism, device.name)
        .getCharacteristic(Characteristic.LockTargetState)
        .on 'set', (value, callback) =>
          if value == Characteristic.LockTargetState.UNSECURED
            env.logger.debug("moving shutter up")
            device.moveUp().then( callback() )
          else if value == Characteristic.LockTargetState.SECURED
            env.logger.debug("moving shutter down")
            device.moveDown().then( callback() )

      @getService(Service.LockMechanism)
        .getCharacteristic(Characteristic.LockTargetState)
        .on 'get', (callback) =>
          device.getPosition().then( (position) =>
            if position == 'up'
              callback(null, Characteristic.LockCurrentState.SECURED)
            else if position == "down"
              callback(null, Characteristic.LockCurrentState.UNSECURED)
            else
              # stopped somewhere in between
              callback(null, Characteristic.LockCurrentState.UNKNOWN)
          )

      # opposite of target position getter
      @getService(Service.LockMechanism)
        .getCharacteristic(Characteristic.LockCurrentState)
        .on 'get', (callback) =>
          device.getPosition().then( (position) =>
            env.logger.debug("returning current position: " + position)
            if position == 'up'
              callback(null, Characteristic.LockCurrentState.UNSECURED)
            else if position == "down"
              callback(null, Characteristic.LockCurrentState.SECURED)
            else
              # stopped somewhere in between
              callback(null, Characteristic.LockCurrentState.UNKNOWN)
          )

  ##
  # TemperatureSensor
  ##
  class TemperatureAccessory extends DeviceAccessory

    constructor: (device) =>
      super(device)

      @addService(Service.TemperatureSensor, device.name)
        .getCharacteristic(Characteristic.CurrentTemperature)
        .on 'get', (callback) =>
          device.getTemperature().then( (temp) =>
            env.logger.debug("returning current temperature: " + temp)
            callback(null, temp)
          )

  ##
  # ContactSensor
  ##
  class ContactAccessory extends DeviceAccessory

    constructor: (device) =>
      super(device)

      @addService(Service.ContactSensor, device.name)
        .getCharacteristic(Characteristic.ContactSensorState)
        .on 'get', (callback) =>
          device.getContact().then( (state) =>
            env.logger.debug("returning contact sensor state: " + state)
            if state == 'closed'
              callback(null, Characteristic.ContactSensorState.CONTACT_DETECTED)
            else
              callback(null, Characteristic.ContactSensorState.CONTACT_NOT_DETECTED)
          )

  class

  return plugin
