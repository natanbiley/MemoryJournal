# Rich Text Editing Features

## Overview
Your Memory Journal app now includes a comprehensive rich text editor with extensive formatting capabilities. The implementation uses `NSAttributedString` and `UITextView` to provide native iOS text editing features.

## Features Implemented

### 1. **Text Styling**
- **Bold**: Make text bold using the bold button
- **Italic**: Italicize text for emphasis
- **Underline**: Add underline to text
- **Strikethrough**: Strike through text for completed items or edits

### 2. **Font Size Control**
- **Increase Font Size**: Make text larger (up to 72pt)
- **Decrease Font Size**: Make text smaller (down to 8pt)
- Dynamic font size adjustment per selection

### 3. **Text Alignment**
- **Left Align**: Align text to the left
- **Center Align**: Center text in the editor
- **Right Align**: Align text to the right
- Alignment applies to entire paragraphs

### 4. **Color Formatting**
- **Text Color**: Change the color of selected text
  - 15 preset colors including black, gray, red, blue, green, etc.
  - Custom color picker for precise color selection
- **Background Color**: Highlight text with background colors
  - Same color options as text color
  - Great for emphasizing important passages

### 5. **List Formatting**
- **Bullet Points**: Insert bullet points for lists
- Quick access button for creating bulleted lists

### 6. **Clear Formatting**
- Remove all formatting from selected text
- Reset to default system font and color

### 7. **Rich Text Persistence**
- Text is stored as HTML in the database
- Maintains all formatting between editing sessions
- Plain text fallback for compatibility
- Automatic conversion between plain text and rich text

## How to Use

### Basic Formatting
1. Select the text you want to format
2. Tap the desired formatting button in the toolbar
3. The formatting is applied immediately

### Changing Colors
1. Select text
2. Tap the text color (A) or background color (paintbrush) button
3. Choose from preset colors or use the custom color picker
4. Tap "Apply" to confirm

### Font Size
1. Select text
2. Use the "A−" button to decrease size or "A+" to increase size
3. Each tap changes size by 2 points

### Text Alignment
1. Place cursor in the paragraph you want to align (or select text)
2. Tap left, center, or right alignment buttons
3. The entire paragraph will be aligned

### Creating Lists
1. Place cursor where you want a bullet point
2. Tap the list button
3. A bullet point (•) will be inserted

## Technical Details

### Architecture
- **RichTextEditor**: UIViewRepresentable wrapper around UITextView
- **RichTextManager**: ObservableObject that manages attributed text and formatting operations
- **RichTextToolbar**: SwiftUI toolbar with all formatting controls
- **ColorPickerView**: Custom color selection interface

### Storage
- Rich text is stored as HTML in the `bodyHTML` field
- Plain text is stored in the `bodyText` field for backward compatibility
- HTML is generated using NSAttributedString's built-in HTML export
- HTML is loaded back using NSAttributedString's document import

### Supported Attributes
- Font family and size (`.font`)
- Text color (`.foregroundColor`)
- Background color (`.backgroundColor`)
- Underline (`.underlineStyle`)
- Strikethrough (`.strikethroughStyle`)
- Paragraph alignment (`.paragraphStyle`)
- Bold and italic traits (via font descriptor)

## Keyboard Shortcuts (via UITextView)
The underlying UITextView provides standard iOS text editing:
- **⌘B**: Bold (on external keyboard)
- **⌘I**: Italic (on external keyboard)
- **⌘U**: Underline (on external keyboard)
- Standard iOS text selection gestures

## Future Enhancement Possibilities
- Headings (H1, H2, H3)
- Numbered lists
- Indentation controls
- Link insertion
- Image embedding
- Table support
- Custom fonts
- Undo/Redo buttons
- Markdown import/export
- Copy/paste formatting
- Font family selection

## Accessibility
- All toolbar buttons use SF Symbols for consistent iconography
- Text editor supports VoiceOver
- Color picker includes text labels
- Standard iOS accessibility features are preserved

## Performance Considerations
- Attributed string operations are optimized for selection ranges
- HTML conversion happens only on save
- Toolbar state updates only check current selection location
- Efficient attribute enumeration for font changes

## Compatibility
- iOS 17.0+ (SwiftUI and SwiftData requirements)
- Works on iPhone and iPad
- Supports both portrait and landscape orientations
- Dark mode compatible
