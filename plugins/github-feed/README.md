# GitHub Feed Plugin for Noctalia

Display GitHub activity from users you follow and activity on your own repositories.

## Features

**Activity from Followed Users:**
- Stars - repos they starred
- Forks - repos they forked
- Pull Requests - PRs they opened/merged
- Repository Creations - new repos they created

**Activity on Your Repos:**
- Stars - when someone stars your repo
- Forks - when someone forks your repo

**GitHub Notifications:**
- Overview over notifications you receive

**Technical:**
- Parallel GraphQL fetching for 5-6x faster load times
- Queries ALL followed users efficiently
- Automatic retry on transient failures
- Caches results to minimize API calls
- Displays user avatars
- Click events to open in browser

## Requirements

- GitHub Personal Access Token with `read:user` scope
  - If you want to use the notifications feature the token also needs `notifications` scope
- Create one at: https://github.com/settings/tokens

## Configuration

1. Open Noctalia settings
2. Navigate to the GitHub Feed plugin
3. Enter your GitHub username
4. Enter your Personal Access Token
5. Toggle which event types to show
6. Adjust refresh interval and maximum events as needed

## How It Works

### Parallel GraphQL Fetching

The plugin uses GitHub's GraphQL API with parallel requests for maximum speed:

1. Fetches your complete following list via REST API
2. Splits users into batches of 8
3. Runs 6 parallel GraphQL queries simultaneously
4. Each query fetches per user:
   - Last 3 starred repositories
   - Last 2 created repositories
   - Last 2 forked repositories
   - Last 2 pull requests
5. Automatic retry (up to 3 attempts) on failed requests
6. Queries your top 10 repos for recent stars and forks
7. Merges, deduplicates, and sorts events by date
8. Caches results for the configured refresh interval

### Performance

- **Before (v1.0.7)**: ~128 seconds for 137 users (sequential)
- **After (v1.1.0)**: ~20 seconds for 137 users (parallel)
- **Speedup**: 5-6x faster

### API Usage

- REST API: 1 request per 100 followed users
- GraphQL API: ~1 point per batch + 1 point for your repos
- For 137 followed users: ~20 GraphQL points total
- Well within GitHub's rate limits (5000 points/hour)

## IPC Commands

Refresh feed:
```bash
qs -c noctalia-shell ipc call plugin:github-feed refresh
```

Toggle panel:
```bash
qs -c noctalia-shell ipc call plugin:github-feed toggle
```

## Event Types

**From Followed Users:**
- WatchEvent - when they star a repo
- ForkEvent - when they fork a repo
- PullRequestEvent - when they open/merge a PR
- CreateEvent - when they create a new repo

**On Your Repos:**
- WatchEvent - when someone stars your repo
- ForkEvent - when someone forks your repo

## Cache

Events are cached in:
```
~/.config/noctalia/plugins/github-feed/cache/events.json
```

Avatars are cached in:
```
~/.config/noctalia/plugins/github-feed/cache/avatars/
```

To force a fresh fetch, delete the cache directory and refresh.

## Files

```
github-feed/
  manifest.json      # Plugin metadata
  Main.qml           # Core logic, parallel GraphQL fetching
  BarWidget.qml      # Bar button (GitHub icon)
  Panel.qml          # Popup panel with event list
  Settings.qml       # Configuration UI
  cache/
    events.json      # Cached events
    avatars/         # Cached user avatars
```

## Version History

### 1.2.0
- Added GitHub Notifications support
  - Displays unread notification count in bar tooltip
  - Lists detailed notifications in the feed in a separate tab
  - Split view into "Activity" and "Notifications" tabs
  - Added settings toggle to set the default tab
  - Added optional customizable notifications badge to bar icon
- Added optional system notifications for events and notifications

### 1.1.0
- Parallel GraphQL fetching (6 concurrent requests)
- 5-6x faster load times (~20s vs ~128s for 137 users)
- Automatic retry on transient failures (up to 3 attempts)
- Improved error handling and logging

### 1.0.7
- Added forks from followed users
- Added pull requests from followed users
- Added stars/forks on YOUR repositories
- Separate toggles for each event type
- Improved event display formatting

### 1.0.5
- Complete rewrite using GraphQL batching
- Queries ALL followed users (previously limited)
- Simplified to stars and repo creations
- Improved caching and error handling
- Fixed avatar loading

### 1.0.3
- Initial REST API implementation
- Limited to configurable number of users

## License

MIT
