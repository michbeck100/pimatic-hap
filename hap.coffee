
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

      bridge = new Bridge('Pimatic HomeKit Bridge', uuid.generate("Pimatic HomeKit Bridge"))

      @framework.on 'deviceAdded', (device) =>
        env.logger.debug("try to add device " + device.name)
        if device instanceof env.devices.DimmerActuator
          env.logger.debug("adding dimmer " + device.name)
        else if device instanceof env.devices.SwitchActuator
          powerSwitch = new PowerSwitchAccessory(device)
          bridge.addBridgedAccessory(powerSwitch)
        else
          env.logger.error("unsupported device type " + device.type)
        env.logger.debug("added device " + device.name)

      @framework.once "after init", =>
        # publish homekit bridge
        # TODO: Make settings configurable
        bridge.publish({
          username: this.generateUniqueUsername(bridge.displayName),
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

  plugin = new HapPlugin()

  # base class for switch actuators
  # class SwitchAccessory


  class PowerSwitchAccessory extends Accessory

    constructor: (@device) ->
      uuid = uuid.generate('pimatic-hap:accessories:switch:' + @device.id)
      super(@device.name, uuid)

      @getService(Service.AccessoryInformation)
        .setCharacteristic(Characteristic.Manufacturer, "Pimatic")
        .setCharacteristic(Characteristic.Model, "Rev-1")
        .setCharacteristic(Characteristic.SerialNumber, uuid);

      @on 'identify', (paired, callback) =>
        env.logger.debug("PowerSwitchAccessory identify")
        callback()

      @addService(Service.Switch, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          env.logger.debug("changing state to " + value)
          @device.changeStateTo(value).then( callback() )

      @getService(Service.Switch)
        .getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          @device.getState().then( (state) => callback(state) )

  return plugin
