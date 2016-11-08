module.exports = (env) ->

  BaseAccessory = require('./base')(env)

  # base class for homekit accessories that use a single Service
  class DefaultAccessory extends BaseAccessory

    supportedServiceOverrides: {}

    service: null

    constructor: (device, service) ->
      super(device)
      service = @getServiceOverride(device.config?.hap) unless service
      @service = @addService(service, device.name)

    getServiceOverride: (hapConfig) =>
      if hapConfig?.service of @supportedServiceOverrides
        return @supportedServiceOverrides[hapConfig.service]
      else
        return @getDefaultService()

    getDefaultService: =>
      throw new Error "getDefaultService must be overridden"
