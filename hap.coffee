# activate HAP-NodeJS logging
process.env['DEBUG'] = 'HAPServer,Accessory,EventedHttpServer'

module.exports = (env) =>

  #import accessories
  ButtonAccessory = require('./accessories/button')(env)
  ContactAccessory = require('./accessories/contact')(env)
  DimmerAccessory = require('./accessories/dimmer')(env)
  GenericAccessory = require('./accessories/genericsensor')(env)
  HueLightAccessory = require('./accessories/hue')(env)
  LightbulbAccessory = require('./accessories/lightbulb')(env)
  LedLightAccessory = require('./accessories/ledlight')(env)
  MotionAccessory = require('./accessories/motion')(env)
  PowerSwitchAccessory = require('./accessories/powerswitch')(env)
  ShutterAccessory = require('./accessories/shutter')(env)
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
  _ = require 'lodash'

  # bind hap-nodejs' debug logging to pimatic logger
  Debug = require ('hap-nodejs/node_modules/debug')
  Debug.log = env.logger.debug.bind(env.logger)
  Debug.formatArgs = () => arguments

  class HapPlugin extends env.plugins.Plugin

    knownTemplates: {
      'buttons': ButtonAccessory
      'dimmer': DimmerAccessory
      'huezllonoff': LightbulbAccessory
      'huezlldimmable': DimmerAccessory
      'huezllcolortemp': DimmerAccessory
      'huezllcolor': HueLightAccessory
      'huezllextendedcolor': HueLightAccessory
      'milight-cwww': LightbulbAccessory
      'milight-rgb': DimmerAccessory
      'milight-rgbw': DimmerAccessory
      'switch': PowerSwitchAccessory
      'shutter': ShutterAccessory
      'temperature': GenericAccessory
      'contact': ContactAccessory
      'thermostat': ThermostatAccessory
      'led-light': LedLightAccessory
      'presence': MotionAccessory
    }

    init: (app, @framework, @config) =>
      env.logger.info("Starting homekit bridge")

      hap.init(path.resolve @framework.maindir, '../../hap-database')

      bridge = new Bridge(@config.name, uuid.generate(@config.name))

      bridge.on 'identify', (paired, callback) =>
        env.logger.debug(@config.name + " identify")
        callback()

      @framework.on 'deviceAdded', (device) =>
        accessory = @createAccessoryFromTemplate(device)

        if accessory? && !accessory.exclude()
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

      @framework.deviceManager.deviceConfigExtensions.push(new HapConfigExtension())

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
      if @isKnownDevice(device)
        # ButtonsDevice must not have more than one button
        if device.template is "buttons" and device.config.buttons.length != 1 then return null
        return new @knownTemplates[device.template](device)
      else if device.hasAttribute('temperature') or device.hasAttribute('humidity')
        return new GenericAccessory(device)
      else
        env.logger.debug("unsupported device type: " + device.constructor.name)
        return null

    isKnownDevice: (device) =>
      return device.template of @knownTemplates

  class HapConfigExtension
    configSchema:
      hap:
        type: "object"
        properties:
          service:
            description: "The homekit service to be used for this device"
            type: "string"
            enum: ["Lightbulb", "Switch"]
            required: false
          exclude:
            description: "Whether to exclude this device from being bridged"
            type: "boolean"
            default: false
        required: false

    extendConfigShema: (schema) ->
      for name, def of @configSchema
        schema.properties[name] = _.clone(def)
      env.logger.info JSON.stringify(schema)

    applicable: (schema) ->
      return yes

    apply: (config, device) -> # do nothing here

  plugin = new HapPlugin()

  return plugin
