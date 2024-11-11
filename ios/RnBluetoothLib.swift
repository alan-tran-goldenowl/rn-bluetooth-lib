import Foundation
import CoreBluetooth
import React

@objc(RnBluetoothLib)
class RnBluetoothLib: RCTEventEmitter, CBCentralManagerDelegate, CBPeripheralDelegate {
  // example method multiply
  @objc(multiply:withB:withResolver:withRejecter:)
  func multiply(a: Float, b: Float, resolve:RCTPromiseResolveBlock,reject:RCTPromiseRejectBlock) -> Void {
    resolve(a*b)
  }
  
  // bluetooth methods
  var centralManager: CBCentralManager?
  var discoveredPeripherals: [String: CBPeripheral] = [:]
  var resolveBlock: RCTPromiseResolveBlock?
  var rejectBlock: RCTPromiseRejectBlock?
  var peripheralData: [String: Any] = [:]
  
  override init() {
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: nil)
  }

  private func clearBlocks() {
      self.resolveBlock = nil
      self.rejectBlock = nil
  }
  
  
  @objc(startScan)
  func startScan() {
    print("startScan")
    if centralManager?.state == .poweredOn {
      centralManager?.scanForPeripherals(withServices: nil, options: nil)
      sendEvent(withName: "BLEScanStarted", body: nil)
    }
  }
  
  @objc(stopScan)
  func stopScan() {
    print("stopScan")
    centralManager?.stopScan()
    sendEvent(withName: "BLEScanStopped", body: nil)
  }
  
  // Required method for `RCTEventEmitter`
  override func supportedEvents() -> [String]! {
    return ["BLEScanStarted", "BLEScanStopped", "PeripheralDiscovered", "PeripheralConnected"]
  }
  
  @objc(connectToPeripheral:withResolver:withRejecter:)
  func connectToPeripheral(uuid: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    if resolveBlock != nil || rejectBlock != nil {
        reject("Operation in progress", "Another operation is already in progress", nil)
        return
    }
    print("Attempting to connect to peripheral with UUID: \(uuid)")
    self.resolveBlock = resolve
    self.rejectBlock = reject
    if let peripheral = discoveredPeripherals[uuid] {
      centralManager?.connect(peripheral, options: nil)
    } else {
      reject("Peripheral not found", "Could not find peripheral with UUID \(uuid)", nil)
      clearBlocks()
    }
  }
  
  @objc(disconnectFromPeripheral:withResolver:withRejecter:)
  func disconnectFromPeripheral(uuid: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    if resolveBlock != nil || rejectBlock != nil {
        reject("Operation in progress", "Another operation is already in progress", nil)
        return
    }
    print("Attempting to disconnect from peripheral with UUID: \(uuid)")
    self.resolveBlock = resolve
    self.rejectBlock = reject
    if let peripheral = discoveredPeripherals[uuid] {
      centralManager?.cancelPeripheralConnection(peripheral)
    } else {
      reject("Peripheral not found", "Could not find peripheral with UUID \(uuid)", nil)
      clearBlocks()
    }
  }
  
  
  // CBCentralManagerDelegate methods
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    print("Central state is \(central.state)")
    switch central.state {
    case .poweredOn:
      // Start scanning for peripherals
      // centralManager?.scanForPeripherals(withServices: nil, options: nil)
      break
    default:
      // Handle other states
      break
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    let uuid = peripheral.identifier.uuidString
    discoveredPeripherals[uuid] = peripheral
    // peripheral.delegate = self
    
    let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown Device"
    let peripheralData: [String: Any] = [
      "identifier": uuid,
      "name": name,
      "rssi": RSSI,
      "advertisementData": advertisementData
    ]
    sendEvent(withName: "PeripheralDiscovered", body: peripheralData)
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("Connected to peripheral: \(peripheral.identifier.uuidString)")
    peripheral.delegate = self
    peripheral.discoverServices(nil)
    resolveBlock?("Connected to \(peripheral.identifier.uuidString)")
    clearBlocks()
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    print("Disconnected from peripheral: \(peripheral.identifier.uuidString)")
    if let error = error {
      rejectBlock?("Disconnection failed", "Failed to disconnect from \(peripheral.identifier.uuidString)", error)
    } else {
      resolveBlock?("Disconnected from \(peripheral.identifier.uuidString)")
    }
    clearBlocks()
  }
  
  // CBPeripheralDelegate methods
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    let uuid = peripheral.identifier.uuidString
    print("Discovered services for peripheral: \(uuid)")
    
    if let error = error {
      print("Error discovering services: \(error.localizedDescription)")
      return
    }
    
    guard let services = peripheral.services else { return }
    
    peripheralData = [
      "identifier": uuid,
      "services": [:]
    ]
    for service in services {
      peripheral.discoverCharacteristics(nil, for: service)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    print("Discovered characteristics for service: \(service.uuid)")
    
    if let error = error {
      print("Error discovering characteristics: \(error.localizedDescription)")
      return
    }
    
    guard let characteristics = service.characteristics else { return }
    
    for characteristic in characteristics {
      peripheral.readValue(for: characteristic)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    if let error = error {
      print("Error reading characteristic value: \(error.localizedDescription)")
      return
    }
    guard let value = characteristic.value else {
      print("No value for characteristic: \(characteristic.uuid)")
      return
    }
    
    let valueString = value.map { String(format: "%02x", $0) }.joined()
    print("Updated value for characteristic \(characteristic.uuid): \(valueString)")
    
    // Find the corresponding service and characteristic in peripheralData
    var services:[String: Any] = peripheralData["services"] as? [String: Any] ?? [:]
    services["\(characteristic.uuid)"] = valueString
    peripheralData["services"] = services
    sendEvent(withName: "PeripheralConnected", body: peripheralData)
  }
}
