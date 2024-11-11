/* eslint-disable react-native/no-inline-styles */
import { useState, useEffect } from 'react';
import {
  StyleSheet,
  View,
  Text,
  NativeEventEmitter,
  NativeModules,
  FlatList,
  TouchableOpacity,
  Switch,
  ActivityIndicator,
} from 'react-native';
import {
  startScan,
  stopScan,
  connectToPeripheral,
  disconnectFromPeripheral,
} from 'react-native-rn-bluetooth-lib';
import type { Peripheral } from './Interface/Preipheral';

const { RnBluetoothLib } = NativeModules;
const bluetoothEventEmitter = new NativeEventEmitter(RnBluetoothLib);

export default function App() {
  const [connectingId, setConnectingId] = useState<string>('');
  const [connectedId, setConnectedId] = useState<string>('');
  const [connectionStatus, setConnectionStatus] = useState<string>('');
  const [isScanning, setIsScanning] = useState<boolean>(false);
  const [discoveredPeripherals, setDiscoveredPeripherals] = useState<
    Peripheral[]
  >([]);
  const [connectedDevice, setConnectedDevice] = useState<any>({});

  useEffect(() => {
    const scanStartedListener = bluetoothEventEmitter.addListener(
      'BLEScanStarted',
      () => {
        setIsScanning(true);
      }
    );

    const scanStoppedListener = bluetoothEventEmitter.addListener(
      'BLEScanStopped',
      () => {
        setIsScanning(false);
      }
    );

    const peripheralDiscoveredListener = bluetoothEventEmitter.addListener(
      'PeripheralDiscovered',
      (peripheral: Peripheral) => {
        if (!peripheral.name.includes('Unknown')) {
          setDiscoveredPeripherals((prevPeripherals) => {
            if (
              !prevPeripherals.some(
                (p) => p.identifier === peripheral.identifier
              )
            ) {
              return [...prevPeripherals, peripheral];
            }
            return prevPeripherals;
          });
        }
      }
    );
    const connectedDeviceListener = bluetoothEventEmitter.addListener(
      'PeripheralConnected',
      (device) => {
        setConnectedDevice(device);
      }
    );

    return () => {
      scanStartedListener.remove();
      scanStoppedListener.remove();
      peripheralDiscoveredListener.remove();
      connectedDeviceListener.remove();
    };
  }, []);

  const toggleSwitch = () => {
    if (isScanning) {
      handleStopScan();
    } else {
      handleStartScan();
    }
  };

  const handleStartScan = () => {
    startScan();
    setIsScanning(true);
  };

  const handleStopScan = () => {
    stopScan();
    setDiscoveredPeripherals([]);
    setIsScanning(false);
  };

  const handleConnect = async (id: string) => {
    try {
      setConnectingId(id);
      setConnectedId('');
      const res = await connectToPeripheral(id);
      setConnectedId(id);
      setConnectingId('');
    } catch (error) {
      setConnectingId('');
      setConnectedId('');
      setConnectionStatus(error.message);
    }
  };

  const handleDisconnect = async () => {
    if (connectedId === '') {
      return;
    }
    try {
      setConnectedId('');
      setConnectingId(connectedId);
      const res = await disconnectFromPeripheral(connectedId);
      setConnectedDevice({});
      setConnectingId('');
      setConnectedId('');
    } catch (error) {
      setConnectedId('');
      setConnectingId('');
      setConnectionStatus(error.message);
    }
  };

  const getServicesList = (services: Record<string, any> | null): string => {
    if (!services || typeof services !== 'object') {
      return 'No services available';
    }
    return Object.keys(services)
      .map((service) => `• ${service}: ${services[service]}`)
      .join('\n');
  };

  return (
    <View style={styles.container}>
      <View style={styles.switchContainer}>
        <Text>Bluetooth</Text>
        <Switch onValueChange={toggleSwitch} value={isScanning} />
      </View>
      {connectionStatus.length > 0 && (
        <Text>Connection Status: {connectionStatus}</Text>
      )}
      <FlatList
        style={styles.flatList}
        data={discoveredPeripherals}
        keyExtractor={(item) => item.identifier}
        renderItem={({ item }) => (
          <TouchableOpacity
            onPress={
              connectedId === item.identifier
                ? () => {}
                : () => handleConnect(item.identifier)
            }
          >
            <View style={styles.peripheralItem}>
              <View style={styles.peripheralTitleItem}>
                <Text>{item.name}</Text>
                {/* <Text>{item.identifier}</Text> */}
                {/* <Text>RSSI: {item.rssi}</Text> */}
                {connectingId === item.identifier && (
                  <ActivityIndicator size="small" color="#000000" />
                )}
                {connectedId === item.identifier && (
                  <TouchableOpacity onPress={() => handleDisconnect()}>
                    <Text style={styles.connectedText}>Disconnect ✘</Text>
                  </TouchableOpacity>
                )}
              </View>
              {connectedId === item.identifier && (
                <View>
                  <View style={{ marginTop: 3 }}>
                    <View
                      style={{
                        alignItems: 'flex-end',
                        flexDirection: 'row',
                        justifyContent: 'space-between',
                      }}
                    >
                      <Text>Services:</Text>
                    </View>
                    <Text>{getServicesList(connectedDevice.services)}</Text>
                  </View>
                </View>
              )}
            </View>
          </TouchableOpacity>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'flex-start',
    paddingTop: 130,
  },
  switchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    width: '100%',
    padding: 10,
  },
  flatList: {
    width: '100%',
    padding: 10,
  },
  peripheralItem: {
    flexDirection: 'column',
    padding: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#d3d3d3',
    width: '100%',
  },
  peripheralTitleItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: '100%',
  },
  connectedText: {
    color: 'green',
  },
});
