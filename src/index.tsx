import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-rn-bluetooth-lib' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const RnBluetoothLib = NativeModules.RnBluetoothLib
  ? NativeModules.RnBluetoothLib
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export function multiply(a: number, b: number): Promise<number> {
  return RnBluetoothLib.multiply(a, b);
}

export function startScan(): void {
  return RnBluetoothLib.startScan();
}

export function stopScan(): void {
  return RnBluetoothLib.stopScan();
}

export function connectToPeripheral(uuid: string): Promise<string> {
  return RnBluetoothLib.connectToPeripheral(uuid);
}

export function disconnectFromPeripheral(uuid: string): Promise<string> {
  return RnBluetoothLib.disconnectFromPeripheral(uuid);
}
