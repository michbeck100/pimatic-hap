$(document).on 'templateinit', (event) ->

  class HomekitBridgeDeviceItem extends pimatic.DeviceItem

    constructor: (templData, @device) ->
      super(templData, @device)

    destroy: ->
      super()

    afterRender: (elements) =>
      super(elements)
      renderImage = (image) =>
        $(elements).find('img').attr('src', 'data:image/png;base64,' + image)

      renderImage(@getAttribute('image').value())
      @getAttribute('image').value.subscribe(renderImage)

  pimatic.templateClasses['hap'] = HomekitBridgeDeviceItem
