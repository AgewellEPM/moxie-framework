#!/bin/bash
# Launch SimpleMoxieSwitcher with proper focus

# Kill any existing instances
killall SimpleMoxieSwitcher 2>/dev/null

# Build the app
cd /Users/lukekist/Desktop/SimpleMoxieSwitcher
swift build --configuration release

# Launch and bring to front
.build/release/SimpleMoxieSwitcher &
APP_PID=$!

# Wait a moment for app to start
sleep 1

# Use osascript to bring the app to front and focus
osascript -e 'tell application "SimpleMoxieSwitcher" to activate'

echo "SimpleMoxieSwitcher launched with PID: $APP_PID"
echo "The app window should now be focused and text fields should work!"
