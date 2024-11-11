# react-native-rn-bluetooth-lib

React Native BLE Module for iOS

This is a react-native library to implemented by other projects, you can also try to this lib by running example.

## Run Example
```sh
$ cd example/
$ yarn install
$ npx pod-install
$ open ios/RnBluetoothLibExample.xcworkspace/
```
And run on simulators/devices by xcode


## Troubleshoot
- If app crash on start, maybe app don't have bluetooth permission, please add permission by xcode or manually edit Info.plist

```
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app requires access to Bluetooth to find nearby devices.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to connect to devices.</string>
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
