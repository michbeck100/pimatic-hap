pimatic-hap
=======================

This is a pimatic plugin that starts a HAP-NodeJS Homekit Accessory Server and automatically
publishes all devices configured in pimatic as Homekit Accessories.

Currently the plugin is wip, so not all device types available in pimatic are supported. 

To install the plugin currently it must be cloned to the node_modules directory. Then just 'npm install' and add the plugin to the config.json.

Release to npm-registry will be uploaded soon.

The plugin uses the default credentials from HAP-NodeJS, so just refer to https://github.com/KhaosT/HAP-NodeJS/wiki/Setting-up-iOS-Connection for connecting your iOS device. 
