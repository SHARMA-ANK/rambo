# Rambo Browser - Project Roadmap

## Feature List

### Core Functionality
- [ ] **Cross-Platform Engine**: Support for Android, iOS, Windows, and Linux.
- [ ] **Web Rendering**: Display web pages with JavaScript support.
- [ ] **Navigation**: URL bar, Back, Forward, Refresh, Stop buttons.
- [ ] **Tab Management**: Open, close, and switch between multiple tabs.

### Data & persistence
- [ ] **History**: Record visited websites, view history, clear history.
- [ ] **Caching**: Browser caching for faster loading (managed by the webview engine), with option to clear.
- [ ] **Bookmarks**: Save and manage favorite sites.

### Advanced Features
- [ ] **Downloads Manager**: Handle file downloads, show progress, list downloaded files.
- [ ] **Dark Mode**: System-aware dark/light theme switching.
- [ ] **Search Engine**: Configurable default search engine (Google, Bing, DuckDuckGo etc.).

---

## Development Roadmap

### Phase 1: Initialization & MVP (Minimum Viable Product)
- [x] Setup Flutter project structure.
- [x] Add dependencies for WebView (Mobile & Desktop).
    - `flutter_inappwebview` (Mobile) / `webview_windows` / `webview_linux` (Desktop).
    - Or a unified package if available.
- [x] Create basic UI Layout: AppBar with URL input and WebView body.
- [x] Implement basic navigation (Load URL, Back, Forward, Reload).

### Phase 2: State Management & Tabs
- [x] Set up State Management (Provider).
- [x] Implement Tab Model (BrowserTab & BrowserProvider).
- [x] Build Tab Bar UI (Switching tabs).
- [x] Handle dynamic creation and closing of tabs.

### Phase 3: Essential Browser Features
- [x] Implement **History** storage (using `sqflite`).
- [x] Create History Page UI.
- [x] Implement **Bookmarks** storage and UI.
- [x] Add **Dark Mode** support using `ThemeData` (Improved).

### Phase 4: Desktop & Platform Specifics
- [ ] Ensure Windows support (Keybindings, window sizing).
- [ ] Ensure Linux support.
- [ ] Optimize UI for larger screens (Responsive design).

### Phase 5: Advanced Features & Polish
- [ ] Implement **Downloads** handling.
- [ ] Add Settings page (Clear cache, change search engine).
- [ ] Polish UI/UX (Animations, error pages).
- [ ] Testing & Release preparation.
