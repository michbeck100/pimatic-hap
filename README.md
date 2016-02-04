pimatic-hap
=======================

pimatic-hap is a [pimatic](https://github.com/pimatic/pimatic) plugin that starts a Homekit Accessory Server and automatically
publishes all devices configured in pimatic as Homekit Accessories using a single Accessory bridge.

Currently it supports most devices that pimatic comes with OOB. Some device types cannot be supported because the HomeKit protocol doesn't have similar types.

Since this plugin uses [HAP-NodeJS](https://github.com/KhaosT/HAP-NodeJS), libnss-mdns and libavahi-compat-libdnssd-dev must be installed on a raspberry pi:

    sudo apt-get install libnss-mdns libavahi-compat-libdnssd-dev

To install the plugin just add the plugin to the config.json of pimatic:

    {
      "plugin": "hap"   
    }

This will fetch the most recent version from npm-registry on the next pimatic start and install the plugin.

Please use 031-45-154 as pin, when pairing with the pimatic homekit bridge.

Every iOS app that works with homekit should work with this (like Elgato Eve), so no need for an Apple developer account.

### Sponsoring

Do you like this plugin? Then consider a donation to support development.

<span class="badge-paypal"><a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=2T48JXA589B4Y" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span>

### Changelog
0.5.3
* Updated hap-nodejs to 0.1.8

0.5.2
* [#9](https://github.com/michbeck100/pimatic-hap/issues/9) setting state when dim level changes
* [#18](https://github.com/michbeck100/pimatic-hap/issues/18) fixed identify for led lights
* [#15](https://github.com/michbeck100/pimatic-hap/issues/15) Added Saturation, so Siri changes colors.
* [#22](https://github.com/michbeck100/pimatic-hap/issues/22) Supporting a min temperature of -50 degrees
* Moved to color-convert as single dependency for color computations.

0.5.1
* Added support for motion sensors

0.5.0
* [#12](https://github.com/michbeck100/pimatic-hap/issues/12) added support for humidity sensors that use the temperature device
* debug logging of hap-nodejs bound to pimatic logger
* #14: using turnOn and turnOff methods for switches

0.4.1
* Minor bugfixes

0.4.0
* When setting target temperature, remember the value as current temperature. This is as close as we can get, if device doesn't emit temperature value.
* Notifying iOS devices directly when changing target temperature
* Deleted debug log statements
* determine device type by template, first implementation for BaseLedLight devices
* Added LedLightAccessory

0.3.4
* Ensure that hap database is always at the same place

0.3.3
* Notifying iOS devices actively once temperature changes
* Fixed null check

0.3.2
* [#7](https://github.com/michbeck100/pimatic-hap/issues/7) Explicitly calling method with all parameters

0.3.1
* Updated hap-nodejs dependency to 0.0.7, this changes transitive dependency to node-persist to ^0.0.6
* Fixed error when checking if converter is defined
* Fixed possible infinite loops when device state change triggers iOS notification and notification triggers state change

0.3.0
* [#4](https://github.com/michbeck100/pimatic-hap/issues/4) refactored use of promises
* Fix for restore state at device identify
* updated hap-nodejs dependency to 0.0.6

0.2.2
* contact sensor handling fixed

0.2.1
* [#3](https://github.com/michbeck100/pimatic-hap/issues/3) - fixed error with contact sensor accessory

0.2.0
* support for TemperatureSensor, ContactSensor, HeatingThermostat
* added change notification of iOS devices where possible

0.1.0
* fixed a bug where Homekit Characteristics were not returned correctly

0.0.2
* support for shutters
* implemented identify method for switches, will toggle twice

0.0.1
* initial release
* support for switches and dimmers

### Credit
The original HomeKit API work was done by [KhaosT](http://twitter.com/khaost) in his [HAP-NodeJS](https://github.com/KhaosT/HAP-NodeJS) project.
