//
//  AudioMonitor.swift
//  SoundEffect
//
//  Created by Ali Moeeny on 10/18/25.
//

import Foundation
import CoreAudio

// Define master volume constant (vmvc = virtual master volume control)
private let kAudioHardwareServiceDeviceProperty_VirtualMasterVolume: AudioObjectPropertySelector = 
    0x766d7663 // 'vmvc'

/// Monitors system audio properties using CoreAudio framework
@Observable
class AudioMonitor {
    var volume: Float = 0.0
    var isMuted: Bool = false
    var outputDeviceName: String = ""
    
    fileprivate var defaultOutputDeviceID: AudioDeviceID = 0
    fileprivate var hasLoggedBluetoothWarning = false
    
    init() {
        setupAudioMonitoring()
    }
    
    deinit {
        removePropertyListeners()
    }
    
    // MARK: - Setup
    
    fileprivate func setupAudioMonitoring() {
        // Get default output device
        guard let deviceID = getDefaultOutputDevice() else {
            print("Failed to get default output device")
            return
        }
        
        defaultOutputDeviceID = deviceID
        hasLoggedBluetoothWarning = false
        print("Setting up monitoring for device ID: \(deviceID)")
        
        // Read initial values
        updateVolume()
        updateMuteState()
        updateDeviceName()
        
        // Add property listeners
        addVolumeListener()
        addMuteListener()
        addDefaultDeviceListener()
    }
    
    // MARK: - Get Default Output Device
    
    fileprivate func getDefaultOutputDevice() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var deviceIDSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &deviceIDSize,
            &deviceID
        )
        
        guard status == noErr else {
            print("Error getting default output device: \(status)")
            return nil
        }
        
        return deviceID
    }
    
    // MARK: - Update Properties
    
    fileprivate func updateVolume() {
        var volume = Float32(0.0)
        var volumeSize = UInt32(MemoryLayout<Float32>.size)
        
        // Try element 0 (master volume) first
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )
        
        var status = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &address,
            0,
            nil,
            &volumeSize,
            &volume
        )
        
        // Try main element
        if status != noErr {
            address.mElement = kAudioObjectPropertyElementMain
            status = AudioObjectGetPropertyData(
                defaultOutputDeviceID,
                &address,
                0,
                nil,
                &volumeSize,
                &volume
            )
        }
        
        // Try channel 1 as fallback
        if status != noErr {
            address.mElement = 1
            status = AudioObjectGetPropertyData(
                defaultOutputDeviceID,
                &address,
                0,
                nil,
                &volumeSize,
                &volume
            )
        }
        
        if status == noErr {
            self.volume = volume
            print("Volume updated: \(volume)")
            hasLoggedBluetoothWarning = false
        } else if !hasLoggedBluetoothWarning {
            // For Bluetooth devices that don't expose volume, just keep last known value
            print("⚠️ Volume not available for this device (common for Bluetooth devices)")
            hasLoggedBluetoothWarning = true
        }
    }
    
    fileprivate func updateMuteState() {
        var mute = UInt32(0)
        var muteSize = UInt32(MemoryLayout<UInt32>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &address,
            0,
            nil,
            &muteSize,
            &mute
        )
        
        if status == noErr {
            self.isMuted = mute != 0
            print("Mute state updated: \(isMuted)")
        } else {
            print("Error getting mute state: \(status)")
        }
    }
    
    fileprivate func updateDeviceName() {
        var nameSize = UInt32(MemoryLayout<CFString>.size)
        var name: Unmanaged<CFString>?
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &address,
            0,
            nil,
            &nameSize,
            &name
        )
        
        if status == noErr, let cfString = name?.takeUnretainedValue() {
            self.outputDeviceName = cfString as String
            print("Device name updated: \(outputDeviceName)")
        } else {
            print("Error getting device name: \(status)")
        }
    }
    
    // MARK: - Property Listeners
    
    fileprivate func addVolumeListener() {
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        // Try element 0 (master volume)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0  // Master channel
        )
        
        if AudioObjectHasProperty(defaultOutputDeviceID, &address) {
            let status = AudioObjectAddPropertyListener(
                defaultOutputDeviceID,
                &address,
                volumeChangeCallback,
                selfPointer
            )
            
            if status == noErr {
                print("Added master volume listener (element 0)")
                return
            }
        }
        
        // Try element 1 (main/first channel)
        address.mElement = kAudioObjectPropertyElementMain
        if AudioObjectHasProperty(defaultOutputDeviceID, &address) {
            let status = AudioObjectAddPropertyListener(
                defaultOutputDeviceID,
                &address,
                volumeChangeCallback,
                selfPointer
            )
            
            if status == noErr {
                print("Added device-specific volume listener")
                return
            }
        }
        
        // Try individual channels (1 and 2 for stereo)
        for channel: UInt32 in 1...2 {
            address.mElement = channel
            if AudioObjectHasProperty(defaultOutputDeviceID, &address) {
                let status = AudioObjectAddPropertyListener(
                    defaultOutputDeviceID,
                    &address,
                    volumeChangeCallback,
                    selfPointer
                )
                
                if status == noErr {
                    print("Added volume listener for channel \(channel)")
                }
            }
        }
        
        print("Note: Bluetooth devices may not support volume monitoring via CoreAudio")
    }
    
    fileprivate func addMuteListener() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        AudioObjectAddPropertyListener(
            defaultOutputDeviceID,
            &address,
            muteChangeCallback,
            selfPointer
        )
    }
    
    private func addDefaultDeviceListener() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            deviceChangeCallback,
            selfPointer
        )
    }
    
    fileprivate func removePropertyListeners() {
        guard defaultOutputDeviceID != 0 else { return }
        
        print("Removing listeners for device ID: \(defaultOutputDeviceID)")
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        // Remove volume listeners for all possible elements
        var volumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )
        AudioObjectRemovePropertyListener(defaultOutputDeviceID, &volumeAddress, volumeChangeCallback, selfPointer)
        
        volumeAddress.mElement = kAudioObjectPropertyElementMain
        AudioObjectRemovePropertyListener(defaultOutputDeviceID, &volumeAddress, volumeChangeCallback, selfPointer)
        
        for channel: UInt32 in 1...2 {
            volumeAddress.mElement = channel
            AudioObjectRemovePropertyListener(defaultOutputDeviceID, &volumeAddress, volumeChangeCallback, selfPointer)
        }
        
        // Remove mute listener
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectRemovePropertyListener(defaultOutputDeviceID, &muteAddress, muteChangeCallback, selfPointer)
    }
}

// MARK: - C Callbacks

private func volumeChangeCallback(
    _ inObjectID: AudioObjectID,
    _ inNumberAddresses: UInt32,
    _ inAddresses: UnsafePointer<AudioObjectPropertyAddress>,
    _ inClientData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let clientData = inClientData else { return noErr }
    
    let monitor = Unmanaged<AudioMonitor>.fromOpaque(clientData).takeUnretainedValue()
    
    DispatchQueue.main.async {
        monitor.updateVolume()
    }
    
    return noErr
}

private func muteChangeCallback(
    _ inObjectID: AudioObjectID,
    _ inNumberAddresses: UInt32,
    _ inAddresses: UnsafePointer<AudioObjectPropertyAddress>,
    _ inClientData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let clientData = inClientData else { return noErr }
    
    let monitor = Unmanaged<AudioMonitor>.fromOpaque(clientData).takeUnretainedValue()
    
    DispatchQueue.main.async {
        monitor.updateMuteState()
    }
    
    return noErr
}

private func deviceChangeCallback(
    _ inObjectID: AudioObjectID,
    _ inNumberAddresses: UInt32,
    _ inAddresses: UnsafePointer<AudioObjectPropertyAddress>,
    _ inClientData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let clientData = inClientData else { return noErr }
    
    let monitor = Unmanaged<AudioMonitor>.fromOpaque(clientData).takeUnretainedValue()
    
    DispatchQueue.main.async {
        print("Output device changed, re-initializing...")
        monitor.removePropertyListeners()
        
        // Get new device
        guard let newDeviceID = monitor.getDefaultOutputDevice() else {
            print("Failed to get new output device")
            return
        }
        
        monitor.defaultOutputDeviceID = newDeviceID
        print("New device ID: \(newDeviceID)")
        
        // Update all properties
        monitor.updateVolume()
        monitor.updateMuteState()
        monitor.updateDeviceName()
        
        // Re-add listeners for new device
        monitor.addVolumeListener()
        monitor.addMuteListener()
    }
    
    return noErr
}
