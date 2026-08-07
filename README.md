# YTMac

A native macOS video downloader with a modern SwiftUI interface. YTMac wraps [yt-dlp](https://github.com/yt-dlp/yt-dlp) to provide a simple, elegant way to download videos from YouTube and 1000+ other supported sites.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Native macOS Experience** — Built with SwiftUI, follows macOS Human Interface Guidelines
- **1000+ Supported Sites** — Download from YouTube, Vimeo, Twitter, and many more via yt-dlp
- **Batch Downloads** — Paste multiple URLs to download several videos simultaneously (up to 3 concurrent)
- **Progress Tracking** — Real-time progress bars with download speed and ETA for each video
- **Quality Selection** — Choose from 360p to 720p in the free version
- **Download History** — Persistent history of all downloads with re-download capability
- **Auto-Updating yt-dlp** — Automatic daily checks for yt-dlp updates to keep site support current
- **Light & Dark Mode** — Full support for both macOS appearance modes
- **Configurable Save Location** — Choose where downloaded videos are saved

## System Requirements

- **macOS 13.0 (Ventura)** or later
- Internet connection for downloading videos
- Approximately 100 MB of disk space (plus space for downloaded videos)

## Installation

### From DMG (Recommended)

1. Download the latest `.dmg` file from the [GitHub Releases](../../releases) page
2. Open the DMG file
3. Drag **YTMac** to your **Applications** folder
4. Launch YTMac from Applications or Spotlight
5. If prompted by Gatekeeper, right-click the app and select "Open" on first launch

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/ytmac.git
   cd ytmac/YTMac
   ```
2. Open `YTMac.xcodeproj` in Xcode 15+
3. Select the "YTMac" scheme and your Mac as the run destination
4. Build and run (⌘R)

## Usage

### Downloading a Video

1. Launch YTMac
2. Paste a video URL into the input field at the top
3. Select your preferred quality (360p, 480p, or 720p)
4. Click **Download**
5. Watch the progress in the downloads list below

<!-- Screenshots placeholder: Add screenshots of the main download interface here -->

### Batch Downloads

Paste multiple URLs separated by newlines or commas to download several videos at once. YTMac processes up to 3 downloads simultaneously and queues the rest.

### Changing Download Location

1. Go to **Settings** (via the sidebar or ⌘,)
2. Click **Change** next to the download location
3. Select your preferred folder

### Download History

View your download history in the **History** tab. From here you can:
- See all past downloads with their status
- Re-download previously downloaded videos
- Clear your download history

### Updating yt-dlp

YTMac automatically checks for yt-dlp updates every 24 hours. You can also manually check from **Settings → Check for Updates**.

## Supported Sites

YTMac supports all sites that yt-dlp supports — over 1000 websites including:

- YouTube (videos, shorts, playlists)
- Vimeo
- Twitter/X
- Reddit
- Instagram
- TikTok
- Dailymotion
- Twitch (clips and VODs)
- SoundCloud (audio)
- And many more...

For the full list of supported sites, see the [yt-dlp supported sites documentation](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md).

## Attribution

YTMac is powered by [yt-dlp](https://github.com/yt-dlp/yt-dlp), a feature-rich command-line audio/video downloader. yt-dlp is a fork of youtube-dl with additional features and fixes, released under the [Unlicense](https://github.com/yt-dlp/yt-dlp/blob/master/LICENSE).

This project would not be possible without the incredible work of the yt-dlp maintainers and contributors.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Here's how to get started:

### Reporting Issues

- Use [GitHub Issues](../../issues) to report bugs or request features
- Include your macOS version, YTMac version, and steps to reproduce
- Attach relevant log files from `~/Library/Logs/YTMac/ytmac.log` if applicable

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes following the existing code style (MVVM, SwiftUI, actor-based concurrency)
4. Write tests for new functionality
5. Commit with clear messages: `git commit -m "Add: description of change"`
6. Push to your fork: `git push origin feature/my-feature`
7. Open a Pull Request with a description of your changes

### Development Guidelines

- Follow Swift naming conventions and macOS Human Interface Guidelines
- Use Swift structured concurrency (async/await, actors) for concurrent code
- Maintain separation of concerns: Views → ViewModels → Business Logic → Data
- Write unit tests for business logic and property-based tests for core algorithms
- Keep the UI layer free of business logic

### Code of Conduct

Be respectful, inclusive, and constructive. We're all here to build something useful together.

## Architecture

YTMac follows the MVVM (Model-View-ViewModel) pattern with actor-based concurrency:

```
Views (SwiftUI) → ViewModels (@MainActor) → Business Logic (Actors) → Data Layer
```

Key components:
- **DownloadManager** — Orchestrates download lifecycle and queue management
- **ProcessExecutor** — Executes yt-dlp as a subprocess with progress parsing
- **QualityGate** — Enforces quality restrictions (pluggable for future premium features)
- **BinaryUpdater** — Manages yt-dlp installation and updates

## Privacy

YTMac runs entirely on your Mac. No telemetry, no analytics, no data collection. All downloads and history are stored locally on your machine.

---

Built with ❤️ for macOS
