import SwiftUI
import UIKit
import Combine

// MARK: - Rich Text Editor
struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange
    @Binding var typingAttributes: [NSAttributedString.Key: Any]
    var inputAccessoryView: UIView?
    
    var font: UIFont = .systemFont(ofSize: 16)
    var textColor: UIColor = .label
    
    func makeUIView(context: Context) -> UITextView {
        let textView = CustomTextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = .clear
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.allowsEditingTextAttributes = true
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .yes
        
        // Set input accessory view
        textView.customInputAccessoryView = inputAccessoryView
        
        // Set initial attributed text
        textView.attributedText = attributedText
        
        // Set typing attributes
        textView.typingAttributes = typingAttributes
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Update input accessory view
        if let customTextView = uiView as? CustomTextView {
            customTextView.customInputAccessoryView = inputAccessoryView
        }
        
        // Update typing attributes
        uiView.typingAttributes = typingAttributes
        
        // Only update if the attributed text has actually changed
        if !uiView.attributedText.isEqual(to: attributedText) {
            uiView.attributedText = attributedText
        }
        
        // Update selection if it changed
        if uiView.selectedRange.location != selectedRange.location || 
           uiView.selectedRange.length != selectedRange.length {
            let safeRange = NSRange(
                location: min(selectedRange.location, uiView.attributedText.length),
                length: min(selectedRange.length, max(0, uiView.attributedText.length - selectedRange.location))
            )
            uiView.selectedRange = safeRange
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        private var selectionUpdateTask: DispatchWorkItem?
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
            parent.selectedRange = textView.selectedRange
            parent.typingAttributes = textView.typingAttributes
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            // Cancel any pending selection updates
            selectionUpdateTask?.cancel()
            
            // Create a new task to update selection after a short delay
            let task = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.parent.selectedRange = textView.selectedRange
                self.parent.typingAttributes = textView.typingAttributes
            }
            selectionUpdateTask = task
            
            // Execute after a brief delay (only update if no new selection changes occur)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: task)
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Handle newline for bullet and numbered lists
            if text == "\n" {
                guard let currentText = textView.text else { return true }
                let nsText = currentText as NSString
                
                // Validate range
                guard range.location <= nsText.length else { return true }
                
                // Get the current line safely
                let safeLocation = min(range.location, nsText.length - 1)
                guard safeLocation >= 0 else { return true }
                
                let lineRange = nsText.lineRange(for: NSRange(location: safeLocation, length: 0))
                guard lineRange.location + lineRange.length <= nsText.length else { return true }
                
                let currentLine = nsText.substring(with: lineRange)
                
                // Check for bullet list
                if let bulletMatch = currentLine.range(of: "^\\s*\u{2022}\\s", options: .regularExpression) {
                    // Check if line is just a bullet (user wants to exit list)
                    let afterBullet = currentLine[bulletMatch.upperBound...]
                    if afterBullet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // Remove the bullet and just add newline
                        let bulletRange = NSRange(bulletMatch, in: currentLine)
                        let absoluteBulletRange = NSRange(location: lineRange.location + bulletRange.location, 
                                                         length: bulletRange.length)
                        // Validate the range before replacing
                        guard absoluteBulletRange.location + absoluteBulletRange.length <= nsText.length else {
                            return true
                        }
                        textView.textStorage.replaceCharacters(in: absoluteBulletRange, with: "")
                        return true
                    }
                    
                    // Continue the bullet list
                    let indent = String(currentLine[..<bulletMatch.upperBound])
                    insertText(textView, at: range, text: "\n\(indent)")
                    return false
                }
                
                // Check for numbered list (e.g., "1. ", "2. ", etc.)
                if let numberMatch = currentLine.range(of: "^\\s*(\\d+)\\.\\s", options: .regularExpression) {
                    // Check if line is just a number (user wants to exit list)
                    let afterNumber = currentLine[numberMatch.upperBound...]
                    if afterNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // Remove the number and just add newline
                        let numberRange = NSRange(numberMatch, in: currentLine)
                        let absoluteNumberRange = NSRange(location: lineRange.location + numberRange.location, 
                                                         length: numberRange.length)
                        // Validate the range before replacing
                        guard absoluteNumberRange.location + absoluteNumberRange.length <= nsText.length else {
                            return true
                        }
                        textView.textStorage.replaceCharacters(in: absoluteNumberRange, with: "")
                        return true
                    }
                    
                    // Extract and increment the number
                    let matchedText = String(currentLine[numberMatch])
                    if let numberStr = matchedText.components(separatedBy: ".").first,
                       let number = Int(numberStr.trimmingCharacters(in: .whitespaces)) {
                        let nextNumber = number + 1
                        let leadingSpaces = String(matchedText.prefix(while: { $0.isWhitespace }))
                        insertText(textView, at: range, text: "\n\(leadingSpaces)\(nextNumber). ")
                        return false
                    }
                }
            }
            
            return true
        }
        
        private func insertText(_ textView: UITextView, at range: NSRange, text: String) {
            let beginning = textView.beginningOfDocument
            guard let start = textView.position(from: beginning, offset: range.location),
                  let end = textView.position(from: start, offset: range.length),
                  let textRange = textView.textRange(from: start, to: end) else {
                return
            }
            
            textView.replace(textRange, withText: text)
            let cursor = NSRange(location: range.location + text.count, length: 0)
            textView.selectedRange = cursor
        }
    }
}

// MARK: - Custom TextView with Input Accessory
class CustomTextView: UITextView {
    var customInputAccessoryView: UIView?
    
    override var inputAccessoryView: UIView? {
        get {
            return customInputAccessoryView
        }
        set {
            customInputAccessoryView = newValue
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
}

// MARK: - Rich Text Formatting Manager
class RichTextManager: ObservableObject {
    @Published var attributedText: NSAttributedString
    @Published var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @Published var typingAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 16),
        .foregroundColor: UIColor.label
    ]
    
    init(text: String = "") {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.label
        ]
        self.attributedText = NSAttributedString(string: text, attributes: attributes)
        self.typingAttributes = attributes
    }
    
    init(attributedText: NSAttributedString) {
        self.attributedText = attributedText
    }
    
    // MARK: - Text Formatting Methods
    
    func toggleBold() {
        applyFontTrait(.traitBold)
    }
    
    func toggleItalic() {
        applyFontTrait(.traitItalic)
    }
    
    func toggleUnderline() {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        
        if selectedRange.length > 0 {
            let currentAttributes = mutableText.attributes(at: selectedRange.location, effectiveRange: nil)
            let currentUnderline = currentAttributes[.underlineStyle] as? Int ?? 0
            
            if currentUnderline == 0 {
                mutableText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
            } else {
                mutableText.removeAttribute(.underlineStyle, range: selectedRange)
            }
            attributedText = mutableText
        } else {
            // Apply to typing attributes
            let currentUnderline = typingAttributes[.underlineStyle] as? Int ?? 0
            if currentUnderline == 0 {
                typingAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            } else {
                typingAttributes.removeValue(forKey: .underlineStyle)
            }
        }
    }
    
    func toggleStrikethrough() {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        
        if selectedRange.length > 0 {
            let currentAttributes = mutableText.attributes(at: selectedRange.location, effectiveRange: nil)
            let currentStrikethrough = currentAttributes[.strikethroughStyle] as? Int ?? 0
            
            if currentStrikethrough == 0 {
                mutableText.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
            } else {
                mutableText.removeAttribute(.strikethroughStyle, range: selectedRange)
            }
            attributedText = mutableText
        } else {
            // Apply to typing attributes
            let currentStrikethrough = typingAttributes[.strikethroughStyle] as? Int ?? 0
            if currentStrikethrough == 0 {
                typingAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            } else {
                typingAttributes.removeValue(forKey: .strikethroughStyle)
            }
        }
    }
    
    func setTextColor(_ color: UIColor) {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        
        if selectedRange.length > 0 {
            mutableText.addAttribute(.foregroundColor, value: color, range: selectedRange)
            attributedText = mutableText
        } else {
            // Apply to typing attributes
            typingAttributes[.foregroundColor] = color
        }
    }
    
    func setBackgroundColor(_ color: UIColor) {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        
        if selectedRange.length > 0 {
            mutableText.addAttribute(.backgroundColor, value: color, range: selectedRange)
            attributedText = mutableText
        } else {
            // Apply to typing attributes
            typingAttributes[.backgroundColor] = color
        }
    }
    
    func setFontSize(_ size: CGFloat) {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        
        if selectedRange.length > 0 {
            mutableText.enumerateAttribute(.font, in: selectedRange, options: []) { value, range, _ in
                if let currentFont = value as? UIFont {
                    let newFont = currentFont.withSize(size)
                    mutableText.addAttribute(.font, value: newFont, range: range)
                }
            }
            attributedText = mutableText
        } else {
            // Apply to typing attributes
            if let currentFont = typingAttributes[.font] as? UIFont {
                typingAttributes[.font] = currentFont.withSize(size)
            }
        }
    }
    
    func setAlignment(_ alignment: NSTextAlignment) {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        
        // Apply to entire paragraph containing selection
        let text = mutableText.string as NSString
        let paragraphRange = text.paragraphRange(for: selectedRange)
        
        mutableText.addAttribute(.paragraphStyle, value: paragraphStyle, range: paragraphRange)
        attributedText = mutableText
    }
    
    func increaseFontSize() {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        
        if selectedRange.length > 0 {
            mutableText.enumerateAttribute(.font, in: selectedRange, options: []) { value, range, _ in
                if let currentFont = value as? UIFont {
                    let newSize = min(currentFont.pointSize + 2, 72)
                    let newFont = currentFont.withSize(newSize)
                    mutableText.addAttribute(.font, value: newFont, range: range)
                }
            }
            attributedText = mutableText
        } else {
            // Apply to typing attributes
            if let currentFont = typingAttributes[.font] as? UIFont {
                let newSize = min(currentFont.pointSize + 2, 72)
                typingAttributes[.font] = currentFont.withSize(newSize)
            }
        }
    }
    
    func decreaseFontSize() {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        
        if selectedRange.length > 0 {
            mutableText.enumerateAttribute(.font, in: selectedRange, options: []) { value, range, _ in
                if let currentFont = value as? UIFont {
                    let newSize = max(currentFont.pointSize - 2, 8)
                    let newFont = currentFont.withSize(newSize)
                    mutableText.addAttribute(.font, value: newFont, range: range)
                }
            }
            attributedText = mutableText
        } else {
            // Apply to typing attributes
            if let currentFont = typingAttributes[.font] as? UIFont {
                let newSize = max(currentFont.pointSize - 2, 8)
                typingAttributes[.font] = currentFont.withSize(newSize)
            }
        }
    }
    
    func setFontFamily(_ fontName: String) {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        
        if selectedRange.length > 0 {
            mutableText.enumerateAttribute(.font, in: selectedRange, options: []) { value, range, _ in
                if let currentFont = value as? UIFont {
                    let newFont: UIFont
                    if let font = UIFont(name: fontName, size: currentFont.pointSize) {
                        // Preserve traits if possible
                        let traits = currentFont.fontDescriptor.symbolicTraits
                        if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                            newFont = UIFont(descriptor: descriptor, size: currentFont.pointSize)
                        } else {
                            newFont = font
                        }
                    } else {
                        newFont = currentFont
                    }
                    mutableText.addAttribute(.font, value: newFont, range: range)
                }
            }
            attributedText = mutableText
        } else {
            // Apply to typing attributes
            if let currentFont = typingAttributes[.font] as? UIFont {
                let newFont: UIFont
                if let font = UIFont(name: fontName, size: currentFont.pointSize) {
                    // Preserve traits if possible
                    let traits = currentFont.fontDescriptor.symbolicTraits
                    if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                        newFont = UIFont(descriptor: descriptor, size: currentFont.pointSize)
                    } else {
                        newFont = font
                    }
                } else {
                    newFont = currentFont
                }
                typingAttributes[.font] = newFont
            }
        }
    }
    
    func clearFormatting() {
        if selectedRange.length > 0 {
            let text = attributedText.string as NSString
            let selectedText = text.substring(with: selectedRange)
            
            let mutableText = NSMutableAttributedString(attributedString: attributedText)
            let defaultAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]
            
            mutableText.setAttributes(defaultAttributes, range: selectedRange)
            attributedText = mutableText
        }
    }
    
    // MARK: - List Methods
    
    func toggleBulletList() {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let text = mutableText.string as NSString
        
        // Validate range
        guard selectedRange.location <= text.length else { return }
        let safeRange = NSRange(location: min(selectedRange.location, max(0, text.length - 1)), 
                               length: min(selectedRange.length, max(0, text.length - selectedRange.location)))
        
        // Get the paragraph range
        let paragraphRange = text.paragraphRange(for: safeRange)
        guard paragraphRange.location + paragraphRange.length <= text.length else { return }
        
        let paragraph = text.substring(with: paragraphRange)
        
        // Check if current line already has a bullet
        if paragraph.range(of: "^\u{2022}\\s", options: .regularExpression) != nil {
            // Remove bullet from the beginning of the line
            let newParagraph = paragraph.replacingOccurrences(of: "^\u{2022}\\s", with: "", options: .regularExpression)
            mutableText.replaceCharacters(in: paragraphRange, with: newParagraph)
            
            // Adjust selection
            let lengthDiff = paragraph.count - newParagraph.count
            selectedRange = NSRange(location: max(0, selectedRange.location - lengthDiff), length: selectedRange.length)
        } else {
            // Add bullet at the beginning of the line
            let trimmedParagraph = paragraph.trimmingCharacters(in: .whitespaces)
            let newParagraph = "\u{2022} \(trimmedParagraph)"
            let bulletPrefix = "\u{2022} "
            
            mutableText.replaceCharacters(in: paragraphRange, with: newParagraph)
            
            // Place cursor after the bullet and space
            // For empty lines or cursor at beginning, place after bullet
            if trimmedParagraph.isEmpty || selectedRange.location <= paragraphRange.location {
                selectedRange = NSRange(location: paragraphRange.location + bulletPrefix.count, length: 0)
            } else {
                // Cursor was in the middle of text, maintain relative position
                let lengthDiff = newParagraph.count - paragraph.count
                selectedRange = NSRange(location: selectedRange.location + lengthDiff, length: selectedRange.length)
            }
        }
        
        attributedText = mutableText
    }
    
    func toggleNumberedList() {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        let text = mutableText.string as NSString
        
        // Validate range
        guard selectedRange.location <= text.length else { return }
        let safeRange = NSRange(location: min(selectedRange.location, max(0, text.length - 1)), 
                               length: min(selectedRange.length, max(0, text.length - selectedRange.location)))
        
        // Get the paragraph range
        let paragraphRange = text.paragraphRange(for: safeRange)
        guard paragraphRange.location + paragraphRange.length <= text.length else { return }
        
        let paragraph = text.substring(with: paragraphRange)
        
        // Check if current line already has a number
        if let numberMatch = paragraph.range(of: "^(\\d+)\\.\\s", options: .regularExpression) {
            // Remove number from the beginning of the line
            let newParagraph = paragraph.replacingOccurrences(of: "^(\\d+)\\.\\s", with: "", options: .regularExpression)
            mutableText.replaceCharacters(in: paragraphRange, with: newParagraph)
            
            // Adjust selection
            let lengthDiff = paragraph.count - newParagraph.count
            selectedRange = NSRange(location: max(0, selectedRange.location - lengthDiff), length: selectedRange.length)
        } else {
            // Add number at the beginning of the line
            // Find the line number by counting previous numbered lines
            let textBeforeParagraph = text.substring(to: paragraphRange.location)
            let lines = textBeforeParagraph.components(separatedBy: .newlines)
            
            // Count numbered lines before current line
            var lineNumber = 1
            for line in lines.reversed() {
                if line.range(of: "^(\\d+)\\.\\s", options: .regularExpression) != nil {
                    // Extract the number and increment
                    if let numStr = line.components(separatedBy: ".").first,
                       let num = Int(numStr.trimmingCharacters(in: .whitespaces)) {
                        lineNumber = num + 1
                        break
                    }
                }
            }
            
            let trimmedParagraph = paragraph.trimmingCharacters(in: .whitespaces)
            let newParagraph = "\(lineNumber). \(trimmedParagraph)"
            let numberPrefix = "\(lineNumber). "
            
            mutableText.replaceCharacters(in: paragraphRange, with: newParagraph)
            
            // Place cursor after the number and space
            // For empty lines or cursor at beginning, place after number
            if trimmedParagraph.isEmpty || selectedRange.location <= paragraphRange.location {
                selectedRange = NSRange(location: paragraphRange.location + numberPrefix.count, length: 0)
            } else {
                // Cursor was in the middle of text, maintain relative position
                let lengthDiff = newParagraph.count - paragraph.count
                selectedRange = NSRange(location: selectedRange.location + lengthDiff, length: selectedRange.length)
            }
        }
        
        attributedText = mutableText
    }
    
    func isInBulletList() -> Bool {
        let text = attributedText.string as NSString
        guard text.length > 0, selectedRange.location < text.length else { return false }
        
        let safeLocation = min(selectedRange.location, text.length - 1)
        let paragraphRange = text.paragraphRange(for: NSRange(location: safeLocation, length: 0))
        guard paragraphRange.location + paragraphRange.length <= text.length else { return false }
        
        let paragraph = text.substring(with: paragraphRange)
        return paragraph.range(of: "^\u{2022}\\s", options: .regularExpression) != nil
    }
    
    func isInNumberedList() -> Bool {
        let text = attributedText.string as NSString
        guard text.length > 0, selectedRange.location < text.length else { return false }
        
        let safeLocation = min(selectedRange.location, text.length - 1)
        let paragraphRange = text.paragraphRange(for: NSRange(location: safeLocation, length: 0))
        guard paragraphRange.location + paragraphRange.length <= text.length else { return false }
        
        let paragraph = text.substring(with: paragraphRange)
        return paragraph.range(of: "^(\\d+)\\.\\s", options: .regularExpression) != nil
    }
    
    // MARK: - Helper Methods
    
    private func applyFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        let mutableText = NSMutableAttributedString(attributedString: attributedText)
        
        if selectedRange.length > 0 {
            mutableText.enumerateAttribute(.font, in: selectedRange, options: []) { value, range, _ in
                guard let currentFont = value as? UIFont else { return }
                
                let currentTraits = currentFont.fontDescriptor.symbolicTraits
                var newTraits = currentTraits
                
                if currentTraits.contains(trait) {
                    newTraits.remove(trait)
                } else {
                    newTraits.insert(trait)
                }
                
                if let newFontDescriptor = currentFont.fontDescriptor.withSymbolicTraits(newTraits) {
                    let newFont = UIFont(descriptor: newFontDescriptor, size: currentFont.pointSize)
                    mutableText.addAttribute(.font, value: newFont, range: range)
                }
            }
            attributedText = mutableText
        } else {
            // Apply to typing attributes
            if let currentFont = typingAttributes[.font] as? UIFont {
                let currentTraits = currentFont.fontDescriptor.symbolicTraits
                var newTraits = currentTraits
                
                if currentTraits.contains(trait) {
                    newTraits.remove(trait)
                } else {
                    newTraits.insert(trait)
                }
                
                if let newFontDescriptor = currentFont.fontDescriptor.withSymbolicTraits(newTraits) {
                    let newFont = UIFont(descriptor: newFontDescriptor, size: currentFont.pointSize)
                    typingAttributes[.font] = newFont
                }
            }
        }
    }
    
    func isBold() -> Bool {
        if selectedRange.length > 0 && selectedRange.location < attributedText.length {
            if let font = attributedText.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont {
                return font.fontDescriptor.symbolicTraits.contains(.traitBold)
            }
        } else {
            // Check typing attributes
            if let font = typingAttributes[.font] as? UIFont {
                return font.fontDescriptor.symbolicTraits.contains(.traitBold)
            }
        }
        return false
    }
    
    func isItalic() -> Bool {
        if selectedRange.length > 0 && selectedRange.location < attributedText.length {
            if let font = attributedText.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont {
                return font.fontDescriptor.symbolicTraits.contains(.traitItalic)
            }
        } else {
            // Check typing attributes
            if let font = typingAttributes[.font] as? UIFont {
                return font.fontDescriptor.symbolicTraits.contains(.traitItalic)
            }
        }
        return false
    }
    
    func isUnderlined() -> Bool {
        if selectedRange.length > 0 && selectedRange.location < attributedText.length {
            if let underline = attributedText.attribute(.underlineStyle, at: selectedRange.location, effectiveRange: nil) as? Int {
                return underline != 0
            }
        } else {
            // Check typing attributes
            if let underline = typingAttributes[.underlineStyle] as? Int {
                return underline != 0
            }
        }
        return false
    }
    
    // Convert to plain text
    func getPlainText() -> String {
        return attributedText.string
    }
    
    // Convert to HTML for storage
    func getHTMLString() -> String? {
        let documentAttributes: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        guard let htmlData = try? attributedText.data(from: NSRange(location: 0, length: attributedText.length),
                                                        documentAttributes: documentAttributes) else {
            return nil
        }
        
        return String(data: htmlData, encoding: .utf8)
    }
    
    // Load from HTML
    static func fromHTML(_ html: String) -> RichTextManager? {
        guard let data = html.data(using: .utf8) else { return nil }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return nil
        }
        
        return RichTextManager(attributedText: attributedString)
    }
}

// MARK: - Rich Text Toolbar
struct RichTextToolbar: View {
    @ObservedObject var manager: RichTextManager
    @Binding var showPhotoPicker: Bool
    @Binding var showVideoPicker: Bool
    var onPhotoButtonTap: (() -> Void)? = nil
    var onVideoButtonTap: (() -> Void)? = nil
    @State private var showColorPicker = false
    @State private var showBackgroundColorPicker = false
    @State private var showFontPicker = false
    @State private var selectedColor: Color = .black
    @State private var selectedBackgroundColor: Color = .clear
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Photo Picker
                ToolbarButton(
                    icon: "photo.on.rectangle.angled",
                    isActive: false,
                    action: { 
                        if let onPhotoButtonTap = onPhotoButtonTap {
                            onPhotoButtonTap()
                        } else {
                            showPhotoPicker = true
                        }
                    }
                )
                
                // Video Picker
                ToolbarButton(
                    icon: "video.fill",
                    isActive: false,
                    action: { 
                        if let onVideoButtonTap = onVideoButtonTap {
                            onVideoButtonTap()
                        } else {
                            showVideoPicker = true
                        }
                    }
                )
                
                Divider()
                    .frame(height: 20)
                
                // Font Family
                Button(action: { showFontPicker.toggle() }) {
                    Image(systemName: "textformat.abc")
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                        .foregroundColor(.primary)
                        .background(showFontPicker ? Color.gray.opacity(0.2) : Color.clear)
                        .cornerRadius(6)
                }
                .popover(isPresented: $showFontPicker) {
                    FontPickerView(manager: manager, isPresented: $showFontPicker)
                        .frame(width: .infinity, height: .infinity)
                }
                
                Divider()
                    .frame(height: 20)
                
                // Bold
                ToolbarButton(
                    icon: "bold",
                    isActive: manager.isBold(),
                    action: { manager.toggleBold() }
                )
                
                // Italic
                ToolbarButton(
                    icon: "italic",
                    isActive: manager.isItalic(),
                    action: { manager.toggleItalic() }
                )
                
                // Underline
                ToolbarButton(
                    icon: "underline",
                    isActive: manager.isUnderlined(),
                    action: { manager.toggleUnderline() }
                )
                
                // Strikethrough
                ToolbarButton(
                    icon: "strikethrough",
                    isActive: false,
                    action: { manager.toggleStrikethrough() }
                )
                
                Divider()
                    .frame(height: 20)
                
                // Font Size
                ToolbarButton(
                    icon: "textformat.size.smaller",
                    isActive: false,
                    action: { manager.decreaseFontSize() }
                )
                
                ToolbarButton(
                    icon: "textformat.size.larger",
                    isActive: false,
                    action: { manager.increaseFontSize() }
                )
                
                Divider()
                    .frame(height: 20)
                
                // Lists
                ToolbarButton(
                    icon: "list.bullet",
                    isActive: manager.isInBulletList(),
                    action: { manager.toggleBulletList() }
                )
                
                ToolbarButton(
                    icon: "list.number",
                    isActive: manager.isInNumberedList(),
                    action: { manager.toggleNumberedList() }
                )
                
                Divider()
                    .frame(height: 20)
                
                // Alignment
                ToolbarButton(
                    icon: "text.alignleft",
                    isActive: false,
                    action: { manager.setAlignment(.left) }
                )
                
                ToolbarButton(
                    icon: "text.aligncenter",
                    isActive: false,
                    action: { manager.setAlignment(.center) }
                )
                
                ToolbarButton(
                    icon: "text.alignright",
                    isActive: false,
                    action: { manager.setAlignment(.right) }
                )
                
                Divider()
                    .frame(height: 20)
                
                // Text Color
                Button(action: { showColorPicker.toggle() }) {
                    Image(systemName: "textformat")
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                        .foregroundColor(.primary)
                        .background(showColorPicker ? Color.gray.opacity(0.2) : Color.clear)
                        .cornerRadius(6)
                }
                .popover(isPresented: $showColorPicker) {
                    ColorPickerView(selectedColor: $selectedColor) { color in
                        manager.setTextColor(UIColor(color))
                        showColorPicker = false
                    }
                    .frame(width: 280, height: 350)
                }
                
                // Background Color
                Button(action: { showBackgroundColorPicker.toggle() }) {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                        .foregroundColor(.primary)
                        .background(showBackgroundColorPicker ? Color.gray.opacity(0.2) : Color.clear)
                        .cornerRadius(6)
                }
                .popover(isPresented: $showBackgroundColorPicker) {
                    ColorPickerView(selectedColor: $selectedBackgroundColor) { color in
                        manager.setBackgroundColor(UIColor(color))
                        showBackgroundColorPicker = false
                    }
                    .frame(width: 280, height: 350)
                }
                
                Divider()
                    .frame(height: 20)
                
                // Clear Formatting
                ToolbarButton(
                    icon: "trash",
                    isActive: false,
                    action: { manager.clearFormatting() }
                )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemGray6))
    }
}

struct ToolbarButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 32, height: 32)
                .foregroundColor(isActive ? .white : .primary)
                .background(isActive ? Color.blue : Color.clear)
                .cornerRadius(6)
        }
    }
}

// MARK: - Color Picker View
struct ColorPickerView: View {
    @Binding var selectedColor: Color
    let onColorSelected: (Color) -> Void
    
    let colors: [Color] = [
        .black, .gray, .white,
        .red, .orange, .yellow,
        .green, .blue, .purple,
        .pink, .brown, .cyan,
        .indigo, .mint, .teal
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select Color")
                .font(.headline)
                .padding(.top)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                        )
                        .onTapGesture {
                            selectedColor = color
                            onColorSelected(color)
                        }
                }
            }
            .padding()
            
            ColorPicker("Custom Color", selection: $selectedColor, supportsOpacity: false)
                .padding(.horizontal)
            
            Button("Apply") {
                onColorSelected(selectedColor)
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
    }
}

// MARK: - Font Picker View
struct FontPickerView: View {
    @ObservedObject var manager: RichTextManager
    @Binding var isPresented: Bool
    
    let availableFonts: [(name: String, displayName: String)] = [
        ("System", "System"),
        ("Academy Engraved LET", "Academy"),
        ("American Typewriter", "Typewriter"),
        ("Arial", "Arial"),
        ("Avenir", "Avenir"),
        ("Baskerville", "Baskerville"),
        ("Bodoni 72", "Bodoni"),
        ("Chalkboard SE", "Chalkboard"),
        ("Cochin", "Cochin"),
        ("Copperplate", "Copperplate"),
        ("Courier", "Courier"),
        ("Georgia", "Georgia"),
        ("Gill Sans", "Gill Sans"),
        ("Helvetica", "Helvetica"),
        ("Helvetica Neue", "Helvetica Neue"),
        ("Hoefler Text", "Hoefler"),
        ("Marker Felt", "Marker Felt"),
        ("Menlo", "Menlo"),
        ("Noteworthy", "Noteworthy"),
        ("Optima", "Optima"),
        ("Palatino", "Palatino"),
        ("Papyrus", "Papyrus"),
        ("Savoye LET", "Savoye"),
        ("Snell Roundhand", "Snell"),
        ("Times New Roman", "Times"),
        ("Trebuchet MS", "Trebuchet"),
        ("Verdana", "Verdana")
    ]
    
    private func isCurrentFont(_ fontName: String) -> Bool {
        let currentFont: UIFont?
        
        // Check if there's selected text
        if manager.selectedRange.length > 0 && manager.selectedRange.location < manager.attributedText.length {
            currentFont = manager.attributedText.attribute(.font, at: manager.selectedRange.location, effectiveRange: nil) as? UIFont
        } else {
            // Check typing attributes
            currentFont = manager.typingAttributes[.font] as? UIFont
        }
        
        guard let font = currentFont else { return false }
        
        if fontName == "System" {
            // Check if it's the system font
            return font.fontName.contains("SFUI") || font.fontName.contains("SF-UI") || font.familyName == ".SF UI Text" || font.familyName == ".AppleSystemUIFont"
        } else {
            // Check if font family matches
            return font.familyName == fontName || font.fontName.contains(fontName)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Select Font")
                .font(.headline)
                .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(availableFonts, id: \.name) { font in
                        Button(action: {
                            if font.name == "System" {
                                manager.setFontFamily(".SFUI-Regular")
                            } else {
                                manager.setFontFamily(font.name)
                            }
                            isPresented = false
                        }) {
                            HStack {
                                Text(font.displayName)
                                    .font(font.name == "System" ? .body : .custom(font.name, size: 17))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("Aa")
                                    .font(font.name == "System" ? .body : .custom(font.name, size: 17))
                                    .foregroundColor(.secondary)
                                
                                if isCurrentFont(font.name) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(isCurrentFont(font.name) ? Color.blue.opacity(0.1) : Color(UIColor.systemBackground))
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                    }
                }
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}
