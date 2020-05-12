$(document).on 'templateinit', (event) ->

  class HomekitBridgeDeviceItem extends pimatic.DeviceItem

    constructor: (templData, @device) ->
      super(templData, @device)
      attribute = @getAttribute("image")
      @image = ko.observable attribute.value()
      attribute.value.subscribe (newValue) =>
        @image newValue

    destroy: ->
      super()

    afterRender: (elements) =>
      super(elements)

  pimatic.templateClasses['hap'] = HomekitBridgeDeviceItem
