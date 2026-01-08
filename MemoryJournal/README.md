# DayScribe 📔

A beautiful and intuitive journaling app for iOS that helps you capture and preserve your memories with rich text formatting, photos, and videos.

## Overview

DayScribe is a SwiftUI-based iOS application that provides a modern, elegant way to maintain a daily journal. With support for rich text editing, multimedia content, and powerful organization features, it's the perfect companion for documenting your life's moments.

## ✨ Features

### Core Functionality
- **Rich Text Editing**: Write entries with full formatting support (bold, italic, underline, colors, and highlights)
- **Multimedia Support**: Attach photos and videos to your entries
- **Favorites**: Mark important entries for quick access
- **Search**: Quickly find entries with powerful search functionality
- **Sorting**: Organize entries by date or other criteria
- **Bulk Actions**: Select and delete multiple entries at once

### Organization & Review
- **Timeline Views**: 
  - Year view for annual overview
  - Month view for monthly organization
  - Daily entries for detailed journaling
- **Review Feature**: Revisit past memories and reflect on your journey
- **Date-based Organization**: Automatic chronological organization of entries

### Premium Features
- **Extended Photo Support**: Add more photos to your entries
- **Video Attachments**: Capture moments in motion
- **Advanced Review Options**: Enhanced memory review capabilities
- **Free Trial**: 7-day free trial available

## 🏗️ Architecture

### Technology Stack
- **Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Platform**: iOS
- **Monetization**: StoreKit 2 (Subscription-based)

### Key Components

#### Models
- **Entry**: Core data model for journal entries
  - Rich text (HTML) and plain text support
  - External storage for photos and videos
  - Favorite marking
  - Timestamp tracking

#### Views
- **ContentView**: Main tab-based navigation
- **EntryList**: Browse and manage all entries
- **EntryEditor**: Create and edit entries with rich text
- **ReviewView**: Review past memories
- **SettingsView**: App configuration and subscription management
- **PaywallView**: Premium subscription presentation

#### Managers
- **SubscriptionManager**: Handles in-app purchases and premium feature access
- **EntryStore**: Manages entry data operations

#### Editors
- **RichTextEditor**: Custom rich text editing interface with formatting toolbar

## 💎 Subscription System

The app uses a freemium model with two subscription tiers:

- **Monthly Subscription**: `com.memoryjournal.premium.monthly`
- **Yearly Subscription**: `com.memoryjournal.premium.yearly`

### Premium Features Access
- Extended photo limits per entry
- Video attachment capability
- Enhanced review features
- Automatic transaction verification
- Cross-device sync via Apple ID

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- macOS for development
- Apple Developer Account (for subscription features)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/natanbiley/MemoryJournal.git
cd MemoryJournal
```

2. Open the project in Xcode:
```bash
open MemoryJournal.xcodeproj
```

3. Configure your development team in Xcode:
   - Select the project in the navigator
   - Choose your target
   - Select "Signing & Capabilities"
   - Choose your development team

4. Update subscription product IDs (if needed):
   - Open `SubscriptionManager.swift`
   - Update `monthlyProductID` and `yearlyProductID` with your App Store Connect product IDs

5. Build and run:
   - Select your target device or simulator
   - Press `Cmd + R` or click the Run button

## 🧪 Testing

### StoreKit Testing
The app includes a `Configuration.storekit` file for testing subscriptions locally without connecting to App Store Connect.

To test subscriptions:
1. Run the app in the simulator or on a device
2. StoreKit will use the local configuration
3. Test purchases, renewals, and cancellations
4. Use Xcode's StoreKit transaction manager to view and manage test transactions

### Sample Data
The app includes sample entries for testing and preview purposes. Sample data is automatically loaded in Xcode previews.

## 📱 Usage

1. **Creating Entries**
   - Tap the "+" button to create a new entry
   - Use the formatting toolbar for rich text
   - Add photos or videos (premium)
   - Save your entry

2. **Organizing Entries**
   - Browse entries in the list view
   - Mark favorites with the star icon
   - Use search to find specific entries
   - Select multiple entries for bulk operations

3. **Reviewing Memories**
   - Navigate to the Review tab
   - Revisit past entries
   - Reflect on your journey

4. **Managing Subscription**
   - Go to Settings tab
   - View subscription status
   - Start free trial or subscribe
   - Restore purchases if needed

## 📂 Project Structure

```
MemoryJournal/
├── MemoryJournalApp.swift          # App entry point
├── ContentView.swift                # Main navigation
├── Entry.swift                      # Data model
├── EntryList.swift                  # Entry browsing
├── EntryEditor.swift                # Entry creation/editing
├── EntryStore.swift                 # Data operations
├── RichTextEditor.swift             # Rich text interface
├── ReviewView.swift                 # Memory review
├── SettingsView.swift               # App settings
├── SubscriptionManager.swift        # IAP management
├── PaywallView.swift                # Premium subscription
├── SampleData.swift                 # Test data
├── Configuration.storekit           # StoreKit config
├── Assets.xcassets/                 # App assets
├── docs/                            # Documentation
└── help/                            # Technical guides
    ├── ARCHITECTURE.md              # System architecture
    ├── IMPLEMENTATION_SUMMARY.md    # Implementation details
    ├── SUBSCRIPTION_SETUP.md        # Subscription setup guide
    └── TESTING_GUIDE.md             # Testing instructions
```

## 🔒 Privacy & Security

- All data is stored locally on the user's device using SwiftData
- Photos and videos use external storage for efficient memory management
- Subscription transactions are cryptographically verified by Apple
- No personal data is collected or transmitted to third-party servers

## 🛠️ Development

### Key SwiftData Features
- `@Model` for data persistence
- `@Attribute(.externalStorage)` for large media files
- `modelContainer` for data access
- Automatic relationship management

### Observable Pattern
- Uses `@Observable` macro for reactive UI updates
- Subscription status changes automatically reflect in UI
- Efficient state management with minimal boilerplate

## 📄 License

Copyright © 2026 Natan Biley. All rights reserved.

## 🤝 Contributing

This is a personal project. If you'd like to suggest features or report issues, please create an issue in the repository.

## 📧 Contact

For questions or support, please contact the developer through the repository.

---

**Made with ❤️ using SwiftUI and SwiftData**
