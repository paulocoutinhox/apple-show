# Apple Show - Apple TV Slideshow App

A beautiful and elegant slideshow application for Apple TV that displays rotating banners with smooth transitions. Perfect for digital signage, presentations, or showcasing content in waiting rooms, lobbies, or retail environments.

## Features

- **Automatic Slideshow**: Seamlessly rotates through all banners with smooth fade transitions
- **Customizable Intervals**: Configurable timing between slides with both global and per-slide intervals
- **Title Display**: Optional title overlay for each slide with elegant styling
- **Remote Control Integration**: Press the Play/Pause button on your Apple TV remote to reload slides
- **JSON Configuration**: Easy setup through a simple JSON configuration file
- **Error Handling**: Graceful error handling with user-friendly messages
- **Loading States**: Beautiful loading animations while content is being fetched
- **Responsive Design**: Optimized for Apple TV display with proper aspect ratio handling

## JSON Configuration Format

The app loads slides from a JSON configuration file. Here's the required format:

```json
{
  "config": {
    "interval": 10.0
  },
  "slides": [
    {
      "title": "Welcome to Our Store",
      "image": "https://example.com/banner1.jpg",
      "interval": 8.0,
      "order": 1
    },
    {
      "title": "Special Offers",
      "image": "https://example.com/banner2.jpg",
      "interval": 12.0,
      "order": 2
    },
    {
      "image": "https://example.com/banner3.jpg",
      "order": 3
    }
  ]
}
```

### Configuration Fields

#### Global Config
- `interval` (number): Default interval in seconds between slides (used when individual slide doesn't specify an interval)

#### Slide Object
- `title` (string, optional): Title to display over the image
- `image` (string, required): URL of the image to display
- `interval` (number, optional): Custom interval for this specific slide (overrides global interval)
- `order` (number, required): Display order for the slide (slides are sorted by this field in ascending order)

## Usage

### Setup

1. **Configure JSON**: Create a JSON configuration file with your slides and upload it to a publicly accessible URL (e.g., AWS S3, GitHub, or any web server)

2. **Update URL**: In `ContentView.swift`, replace the `jsonURL` constant with your JSON file URL:
   ```swift
   private let jsonURL = "https://your-domain.com/slides-config.json"
   ```

3. **Build and Deploy**: Build the app and deploy it to your Apple TV

### Controls

- **Play/Pause Button**: Press the Play/Pause button on your Apple TV remote to reload all slides from the JSON configuration
- **Automatic Rotation**: Slides automatically advance based on the configured intervals
- **Looping**: When reaching the last slide, the slideshow automatically returns to the first slide

### Image Requirements

- **Format**: JPEG, PNG, or any format supported by iOS
- **Resolution**: Optimized for Apple TV display (1920x1080 recommended)
- **Size**: Ensure images are appropriately sized for web delivery
- **Accessibility**: Images should be publicly accessible via HTTPS

## Technical Details

### Architecture

- **SwiftUI**: Modern declarative UI framework
- **MVVM Pattern**: Clean separation of concerns with ViewModel
- **Async Image Loading**: Efficient image downloading and caching
- **Timer Management**: Robust timer handling for slide transitions
- **Error Handling**: Comprehensive error states and user feedback

### Key Components

- `SlidesViewModel`: Manages slide data, timing, and state
- `PlayPauseCatcher`: Captures remote control input
- `ContentView`: Main UI with slide display and transitions
- `SlidesData`: Data models for JSON parsing

### Transitions

- **Fade Effect**: Smooth opacity transitions between slides
- **Animation**: SwiftUI animations for seamless user experience
- **Loading States**: Progress indicators during content loading

## Requirements

- **Platform**: Apple TV (tvOS 14.0+)
- **Language**: Swift 5.0+
- **Framework**: SwiftUI
- **Network**: Internet connection for loading JSON and images

## Installation

1. Clone or download this repository
2. Open `apple-show.xcodeproj` in Xcode
3. Update the `jsonURL` in `ContentView.swift` with your configuration file
4. Build and run on Apple TV simulator or device

## Development

### Code Formatting

To format the Swift code in this project, run:

```bash
swiftformat apple-show/
```

Make sure you have [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) installed on your system.

## Customization

### Styling

You can customize the appearance by modifying:
- Title font and styling in `ContentView.swift`
- Background colors and opacity
- Transition animations
- Loading screen appearance

### Functionality

Extend the app by adding:
- Different transition effects
- Sound/music support
- Interactive elements
- Multiple JSON sources
- Local image caching

## Troubleshooting

### Common Issues

1. **Images not loading**: Check image URLs are accessible and valid
2. **JSON parsing errors**: Verify JSON format matches the required structure
3. **Network issues**: Ensure Apple TV has internet connectivity
4. **Remote not responding**: Make sure the app has focus for remote input

### Debug Mode

Enable debug information by checking the console output in Xcode during development.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## Support

For support or questions, please open an issue in this repository or contact the maintainers.

## Screenshots

<p align="center">
    <img src="extras/images/screenshot.png" alt="Apple Show Screenshot" width="600">
</p>

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
