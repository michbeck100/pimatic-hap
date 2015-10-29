
module.exports = (env) ->

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

      @framework.on 'deviceAdded', (device) =>
        env.logger.debug("trying to add device " + device.name)
        accessory: null
        if device instanceof env.devices.DimmerActuator
          accessory = new DimmerAccessory(device)
        else if device instanceof env.devices.SwitchActuator
          accessory = new PowerSwitchAccessory(device)
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

  # base class for switch actuators
  class SwitchAccessory extends Accessory

    constructor: (device) ->
      serialNumber = uuid.generate('pimatic-hap:accessories:switch:' + device.id)
      super(device.name, serialNumber)

      @getService(Service.AccessoryInformation)
        .setCharacteristic(Characteristic.Manufacturer, "Pimatic")
        .setCharacteristic(Characteristic.Model, "Rev-1")
        .setCharacteristic(Characteristic.SerialNumber, serialNumber);
      @on 'identify', (paired, callback) =>
        this.identify(paired, callback)

    ## default identify method just logs and calls callback
    identify: (paired, callback) =>
      env.logger.debug("identify method called")
      callback()

  class PowerSwitchAccessory extends SwitchAccessory

    constructor: (device) ->
      super(device)

      @addService(Service.Switch, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          env.logger.debug("changing state of " + this.displayName + " to " + value)
          device.changeStateTo(value).then( callback() )

      @getService(Service.Switch)
        .getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          device.getState().then( (state) => callback(state) )

  class DimmerAccessory extends SwitchAccessory

    constructor: (device) ->
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
          device.getState().then( (state) => callback(state) )

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on 'get', (callback) =>
          device.getDimlevel().then( (dimlevel) => callback(dimlevel) )

      @getService(Service.Lightbulb)
        .getCharacteristic(Characteristic.Brightness)
        .on 'set', (value, callback) =>
          env.logger.debug("changing dimLevel to " + value)
          device.changeDimlevelTo(value).then( callback() )

  return plugin
