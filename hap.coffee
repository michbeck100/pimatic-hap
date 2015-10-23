
module.exports = (env) ->

  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  crypto = env.require 'crypto'

  hap = require 'hap-nodejs'
  Bridge = hap.Bridge
  Accessory = hap.Accessory
  Service = hap.Service
  Characteristic = hap.Characteristic
  uuid = require ('hap-nodejs/lib/util/uuid')
  once = require('hap-nodejs/lib/util/once').once;

  class HapPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      env.logger.info("Starting homekit bridge")
      hap.init()
      bridge = new HapBridge(framework, config)
      @framework.on 'deviceAdded', (device) =>
        bridge.addDevice(device)
      @framework.once "after init", =>
        bridge.publish()

  plugin = new HapPlugin()

  class HapBridge
    bridge: null

    constructor: (@framework, @config) ->
      ## Start by creating our Bridge which will host all loaded Accessories
      this.bridge = new Bridge('Pimatic HomeKit Bridge', uuid.generate("Pimatic HomeKit Bridge"))
      this.bridge.on 'identify', (paired, callback) =>
        env.logger.debug("Node Bridge identify")
        callback()

    addDevice: (device) =>
      env.logger.debug("try to add device " + device.name)
      if device instanceof env.devices.PowerSwitch
        new PowerSwitchAccessory(device, this.bridge)
        env.logger.debug("added device " + device.name)


    publish: =>
      env.logger.debug("publishing...")
      # TODO: Make settings configurable
      this.bridge.publish({
        username: this.generateUniqueUsername(this.bridge.displayName),
        port: 51826,
        pincode: "031-45-154",
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


  class PowerSwitchAccessory

    constructor: (@device, @bridge) ->
      uuid = uuid.generate('pimatic-hap:accessories:switch:' + @device.id)
      accessory = new Accessory(@device.name, uuid)

      accessory
        .getService(Service.AccessoryInformation)
        .setCharacteristic(Characteristic.Manufacturer, "Pimatic")
        .setCharacteristic(Characteristic.Model, "Rev-1")
        .setCharacteristic(Characteristic.SerialNumber, uuid);

      accessory.on 'identify', (paired, callback) =>
        this.identify()
        callback()

      accessory
        .addService(Service.Switch, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          env.logger.debug("changing state to " + value)
          @device.changeStateTo(value)
          callback()

      accessory
        .getService(Service.Switch)
        .getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          env.logger.debug("returning device state=" + @device.state)
          callback(@device.state)


      @bridge.addBridgedAccessory(accessory)

    identify: =>
      env.logger.debug("PowerSwitchAccessory identify")

  return plugin