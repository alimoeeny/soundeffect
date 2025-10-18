# SoundEffect - Custom macOS Volume OSD

## Project Overview
A macOS application that monitors system audio events and displays a custom on-screen display (OSD) overlay, replicating the native macOS volume indicator experience.

## Core Features

### 1. System Audio Event Monitoring
- Monitor volume up/down changes
- Detect mute/unmute events
- Track audio output device changes
- Real-time event capture using CoreAudio framework

### 2. On-Screen Display (OSD)
- Semi-transparent overlay near screen center
- Smooth fade in/out animations
- Auto-dismiss after brief display
- Visual feedback matching native macOS style
- Volume level indicator (bars/progress)
- Mute state icon

## Technical Architecture

### Components
- **AudioManager**: Observable class for CoreAudio event monitoring
- **OSDView**: SwiftUI overlay component with animations
- **WindowController**: Manages borderless, always-on-top window
- **App Configuration**: Background agent (LSUIElement) with no dock icon

### Frameworks & APIs
- **CoreAudio**: `AudioObjectAddPropertyListener` for system audio monitoring
- **SwiftUI**: Modern UI with animations
- **AppKit**: Window management and positioning

### Permissions & Entitlements
- Audio device access
- Sandbox configuration adjustments
- Accessibility permissions (if needed)

## Implementation Plan

### Phase 1: Audio Monitoring
- [x] **Step 1**: Research and set up system audio event monitoring (CoreAudio framework)
  - Study `AudioObjectAddPropertyListener` API
  - Identify property addresses for volume, mute, output device
  - Test basic audio property reading

- [x] **Step 2**: Request necessary permissions and entitlements for system audio access
  - Update entitlements file
  - Configure Info.plist for audio access
  - Add LSUIElement for background agent behavior

- [x] **Step 3**: Create AudioManager to monitor volume, mute, and output device changes
  - Implement `@Observable` or `ObservableObject` class
  - Set up CoreAudio property listeners
  - Publish volume level, mute state, device info
  - Handle listener callbacks and state updates

### Phase 2: OSD UI
- [ ] **Step 4**: Design SwiftUI OSD overlay component (semi-transparent, centered, auto-fade)
  - Create OSDView with volume indicator
  - Design visual elements (bars, icons, background)
  - Implement fade animations with timing
  - Add auto-dismiss logic

- [ ] **Step 5**: Implement window management for OSD (always-on-top, no dock icon, transparent background)
  - Configure NSWindow for overlay behavior
  - Set window level above all apps
  - Remove title bar and background
  - Position at screen center
  - Handle multi-monitor scenarios

### Phase 3: Integration & Polish
- [ ] **Step 6**: Connect audio events to OSD display triggers
  - Bind AudioManager state to OSD visibility
  - Trigger animations on audio changes
  - Debounce rapid changes
  - Reset auto-dismiss timer on new events

- [ ] **Step 7**: Add visual feedback (volume bars, mute icon, fade animations)
  - Implement volume level visualization
  - Add mute/unmute icon states
  - Polish animation curves and timing
  - Match native macOS aesthetic

- [ ] **Step 8**: Test with volume keys and verify OSD behavior matches macOS native feel
  - Test volume up/down keys
  - Test mute toggle
  - Verify timing and positioning
  - Test on multiple displays
  - Validate performance and responsiveness

## Technical Considerations

### Challenges
- **CoreAudio complexity**: Low-level C APIs require careful memory management
- **Window layering**: Must be visible but not block user interaction
- **Sandbox restrictions**: May need specific entitlements for audio access
- **Performance**: Minimize overhead for real-time monitoring
- **Bluetooth devices**: AirPods and other Bluetooth audio devices don't expose volume changes through CoreAudio APIs (macOS limitation). Volume monitoring works for internal speakers, wired headphones, and some USB audio devices.

### Design Goals
- **Native feel**: Match macOS OSD timing, positioning, and aesthetics
- **Lightweight**: Minimal CPU/memory footprint
- **Reliable**: Robust event handling without crashes
- **Extensible**: Architecture supports adding more system events later

## Future Enhancements (Post-MVP)
- Brightness change monitoring
- Keyboard backlight events
- Custom themes and styling options
- User preferences for position, size, duration
- Additional system event types

## Development Notes
- Swift 5.0
- macOS 26.0 deployment target
- SwiftUI for UI layer
- CoreAudio for system integration
