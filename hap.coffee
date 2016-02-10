# activate HAP-NodeJS logging
process.env['DEBUG'] = 'HAPServer,Accessory,EventedHttpServer'

module.exports = (env) =>

  #import accessories
  ContactAccessory = require('./accessories/contact')(env)
  DimmerAccessory = require('./accessories/dimmer')(env)
  LedLightAccessory = require('./accessories/ledlight')(env)
  MotionAccessory = require('./accessories/motion')(env)
  PowerSwitchAccessory = require('./accessories/powerswitch')(env)
  ShutterAccessory = require('./accessories/shutter')(env)
  TemperatureAccessory = require('./accessories/temperature')(env)
  ThermostatAccessory = require('./accessories/thermostat')(env)

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'
  crypto = env.require 'crypto'
  path = require 'path'

  hap = require 'hap-nodejs'
  Bridge = hap.Bridge
  Accessory = hap.Accessory
  Service = hap.Service
  Characteristic = hap.Characteristic
  uuid = require ('hap-nodejs/lib/util/uuid')

  # bind hap-nodejs' debug logging to pimatic logger
  Debug = require ('hap-nodejs/node_modules/debug')
  Debug.log = env.logger.debug.bind(env.logger)
  Debug.formatArgs = () => arguments

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

        if !accessory?.exclude()
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
          category: Accessory.Categories.BRIDGE
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
        when 'switch' then new PowerSwitchAccessory(device)
        when 'shutter' then new ShutterAccessory(device)
        when 'temperature' then new TemperatureAccessory(device)
        when 'contact' then new ContactAccessory(device)
        when 'thermostat' then new ThermostatAccessory(device)
        when 'led-light' then new LedLightAccessory(device)
        when 'presence' then new MotionAccessory(device)
        else
          env.logger.debug("unsupported device type: " + device.constructor.name)
          null

  plugin = new HapPlugin()

  return plugin
