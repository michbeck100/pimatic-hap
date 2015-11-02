pimatic-hap
=======================

pimatic-hap is a [pimatic](https://github.com/pimatic/pimatic) plugin that starts a Homekit Accessory Server and automatically
publishes all devices configured in pimatic as Homekit Accessories.

Currently the plugin is wip, so not all device types available in pimatic are supported.

Since this plugin uses [HAP-NodeJS](https://github.com/KhaosT/HAP-NodeJS), libnss-mdns and libavahi-compat-libdnssd-dev must be installed on a raspberry pi:

    sudo apt-get install libnss-mdns libavahi-compat-libdnssd-dev

To install the plugin just add the plugin to the config.json of pimatic:

    {
      "plugin": "hap"   
    }

This will fetch the most recent version from npm-registry on the next pimatic start and install the plugin.

The plugin uses the default credentials from HAP-NodeJS, so just refer to https://github.com/KhaosT/HAP-NodeJS/wiki/Setting-up-iOS-Connection for connecting your iOS device.

Every iOS app that works with homekit should work with this (like Elgato Eve), so no need for an Apple developer account.
