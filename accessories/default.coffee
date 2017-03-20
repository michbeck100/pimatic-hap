module.exports = (env) ->

  BaseAccessory = require('./base')(env)

  # base class for homekit accessories that use a single Service
  class DefaultAccessory extends BaseAccessory

    supportedServiceOverrides: {}

    service: null

    constructor: (device, service, deviceId, deviceName) ->
      #this handling is needed in order to support pimatic devices
      #which need to be represented by mutiple homekit devices
      #as function overloading is not supportet in node
      if !deviceId?
        #deviceId was omitted in constructor call thus we need to fill it accordingly
        deviceId = device.id
        #same for deviceName
        deviceName = device.name
        #call super without the parameters to propagate that they were not manipulated
        super(device)
      else
        super(device, deviceId, deviceName)
      
      service = @getServiceOverride(device.config?.hap) unless service
      @service = @addService(service, deviceName)
      device.on 'remove', () =>
        env.logger.debug 'removing device ' + deviceName
        @removeService(@service)


    getServiceOverride: (hapConfig) =>
      if hapConfig?.service of @supportedServiceOverrides
        return @supportedServiceOverrides[hapConfig.service]
      else
        return @getDefaultService()

    getDefaultService: =>
      throw new Error "getDefaultService must be overridden"
