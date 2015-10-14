# #Plugin template

# This is an plugin template and mini tutorial for creating pimatic plugins. It will explain the 
# basics of how the plugin system works and how a plugin should look like.

# ##The plugin code

# Your plugin must export a single function, that takes one argument and returns a instance of
# your plugin class. The parameter is an envirement object containing all pimatic related functions
# and classes. See the [startup.coffee](http://sweetpi.de/pimatic/docs/startup.html) for details.
module.exports = (env) ->

# ###require modules included in pimatic
# To require modules that are included in pimatic use `env.require`. For available packages take
# a look at the dependencies section in pimatics package.json

# Require the  bluebird promise library
  #Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  #assert = env.require 'cassert'

  # Include you own depencies with nodes global require function:
  #  
  hap = require 'hap-nodejs'
  Bridge = hap.Bridge
  Accessory = hap.Accessory
  Service = hap.Service
  Characteristic = hap.Characteristic
  uuid = require ('hap-nodejs/lib/util/uuid')
  once = require('hap-nodejs/lib/util/once').once;
  #

  # ###MyPlugin class
  # Create a class that extends the Plugin class and implements the following functions:
  class HapPlugin extends env.plugins.Plugin


    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #  
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins` 
    #     section of the config.json file 
    #     
    # 
    init: (app, @framework, @config) =>
      env.logger.info("Starting homekit bridge")
      hap.init()
      bridge = new HapBridge(framework, config)
      @framework.on 'deviceAdded', (device) =>
        bridge.addDevice(device)
      @framework.once "after init", =>
        bridge.publish()

  # ###Finally
  # Create a instance of my plugin
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
      if device instanceof env.devices.SwitchActuator
        new SwitchAccessory(device, this.bridge)
        env.logger.debug("added device " + device.name)


    publish: =>
      env.logger.debug("publishing...")
      # TODO: Make settings configurable
      this.bridge.publish({
        username: "CC:22:3D:E3:CE:F6",
        port: 51826,
        pincode: "031-45-154",
        category: Accessory.Categories.OTHER
      })


  class SwitchAccessory

    device: null

    constructor: (@device, @bridge) ->
      uuid = uuid.generate('pimatic-hap:accessories:switch')
      accessory = new Accessory(device.name, uuid)
      accessory.username = "1A:2B:3C:4D:5E:FF"
      accessory.pincode = "031-45-154"

      accessory
        .getService(Service.AccessoryInformation)
        .setCharacteristic(Characteristic.Manufacturer, "Oltica")
        .setCharacteristic(Characteristic.Model, "Rev-1")
        .setCharacteristic(Characteristic.SerialNumber, "A1S2NASF88EW");

      accessory.on 'identify', (paired, callback) =>
        this.identify()
        callback()

      accessory
        .addService(Service.Switch, device.name)
        .getCharacteristic(Characteristic.On)
        .on 'set', (value, callback) =>
          env.logger.debug("switching on")
          device.changeStateTo(value)
          callback()

      accessory
        .getService(Service.Switch)
        .getCharacteristic(Characteristic.On)
        .on 'get', (callback) =>
          env.logger.debug("returning device state")
          callback(null, device.state)


      this.bridge.addBridgedAccessory(accessory)

    identify: =>
      env.logger.debug("SwitchAccessory identify")


  # now return plugin to the framework.
  return plugin