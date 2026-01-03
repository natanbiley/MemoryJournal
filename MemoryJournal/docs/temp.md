# MemoryJournal Privacy Policy

This directory contains the privacy policy for MemoryJournal that will be hosted on GitHub Pages.

## Setup Instructions

### Step 1: Enable GitHub Pages

1. Go to your repository on GitHub: https://github.com/natanbiley/MemoryJournal
2. Click on **Settings** (top right)
3. Scroll down to **Pages** in the left sidebar
4. Under "Source", select **Deploy from a branch**
5. Under "Branch", select **main** and set the folder to **/docs**
6. Click **Save**

### Step 2: Wait for Deployment

GitHub will take 1-2 minutes to build and deploy your site. Once ready, your privacy policy will be available at:

**https://natanbiley.github.io/MemoryJournal/**

### Step 3: Add to App Store Connect

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to your MemoryJournal app
3. In the "App Information" section, find "Privacy Policy URL"
4. Enter: `https://natanbiley.github.io/MemoryJournal/`
5. Save

### Step 4: Update Contact Email (IMPORTANT!)

Before publishing, update the contact email in `index.html`:
- Change `natan.biley@example.com` to your actual email address

## Customization

Feel free to modify `index.html` to:
- Update the contact email
- Add more specific details about your app
- Adjust the styling
- Add terms of service if needed

## Notes

- This privacy policy is designed for apps that store data locally and use StoreKit for subscriptions
- It complies with App Store requirements and major privacy regulations (GDPR, CCPA)
- No analytics or third-party tracking is mentioned since MemoryJournal doesn't use any
