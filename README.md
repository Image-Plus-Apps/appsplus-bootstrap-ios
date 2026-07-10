# AppsPlus Bootstrap iOS

AppsPlus Bootstrap is a foundational Swift framework that provides the building blocks needed to bootstrap iOS, tvOS, macOS, and watchOS applications. Rather than implementing features from scratch for each new project, this framework provides protocol-driven abstractions for the most common infrastructure concerns: networking with token-based authentication, multiple layers of local storage, real-time WebSocket communication, and a coordinator-based navigation architecture.

The framework is designed around protocol-first architecture. Every major component is defined as a protocol, with concrete implementations provided alongside. This means you can swap out any implementation (for example, replacing the Keychain-backed secure storage with an in-memory version for testing) without changing your application code. The `AppsPlusTesting` library takes advantage of this by providing mock implementations of every protocol.

## Requirements

- Swift 5.9+
- iOS 15+ / tvOS 13+ / macOS 10.15+ / watchOS 6+
- Xcode 15+

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Image-Plus-Apps/appsplus-bootstrap-ios", from: "0.0.11")
]
```

### Available Libraries

The package is split into three independent libraries so you only import what you need:

- **`AppsPlusData`** — The data layer. Contains all networking, authentication, storage abstractions (Keychain, UserDefaults, Core Data, GRDB), network connectivity monitoring (`NetworkMonitor`), model types, and WebSocket support. This is the core library that most apps will use. It has a dependency on PusherSwift for WebSocket functionality.

- **`AppsPlusUI`** — The UI layer. Contains UIKit-based components (calendar views, search bars, collection view cells, separator views), SwiftUI components (declarative alerts, text-input alerts, a stylable segmented control), SwiftUI helpers (conditional view modifiers, keyboard observation, `apply`/`configure`, `toAnyView`), and the coordinator pattern implementation (`BaseCoordinator`, `NavigableCoordinator`, `AppNavigationStack`). Depends on CombineExtensions.

- **`AppsPlusTesting`** — Test support. Provides mock implementations of all `AppsPlusData` protocols (`MockSecureStorage`, `MockKeyValueStorage`, `MockPersistentStorage`, `MockAuthSessionProvider`, `MockEventSocket`) so you can write unit tests without real backends. Also includes SwiftCheck generators for property-based testing of common types like `Data`, `Date`, `String`, `URL`, `UUID`, `Page`, and `ValidationError`.

### Capability Index

Before building something app-side, check whether the framework already provides it. Each entry links to its section below.

| Need | Use | Module |
|------|-----|--------|
| HTTP requests with token auth & 401 refresh | [`Network` / `NetworkerImpl`](#networking) | `AppsPlusData` |
| Persist / observe the logged-in session | [`AuthSessionProvider`](#authentication) | `AppsPlusData` |
| Detect online/offline & react to reconnect | [`NetworkMonitor`](#connectivity-monitoring) | `AppsPlusData` |
| Real-time events | [`EventSocket` / `PusherEventSocket`](#websockets) | `AppsPlusData` |
| User defaults / Keychain / SQLite storage | [Storage](#storage) | `AppsPlusData` |
| Present a native alert from a view model | [`AppAlert` + `.appAlert(_:)`](#appalert) | `AppsPlusUI` |
| Alert with text/secure input fields | [`AppInputAlert` + `.appInputAlert(_:)`](#appinputalert-ios-17) | `AppsPlusUI` |
| Present an alert from a `UIViewController` | [`showAlert(...)`](#uikit-components) | `AppsPlusUI` |
| Fully stylable segmented control | [`StyledSegmentedControl`](#swiftui-components) | `AppsPlusUI` |
| SwiftUI navigation stack + coordinators | [`AppNavigationStack` / `NavigableCoordinator`](#navigation) | `AppsPlusUI` |
| Inline view transforms / type erasure | [`apply` / `configure` / `toAnyView`](#swiftui-view-extensions) | `AppsPlusUI` |
| Async image loading | [`AsyncImageView` / `IPAsyncImageView`](#uikit-components) | `AppsPlusUI` |
| Validate trimmed input | [`String.isBlank`](#utilities) | `AppsPlusData` |

---

## Networking

### Architecture

The networking layer is built around three protocols that work together:

- **`Network`** — The top-level protocol. It has a single method: `perform(request:) async throws -> (data: Data, response: HTTPURLResponse)`. This is what your application code calls.

- **`Authenticator`** — Responsible for decorating a `Request` with authentication credentials. It receives a raw request and returns a fully authenticated `URLRequest`. The authenticator also handles token refresh when credentials expire.

- **`Request`** — A lightweight wrapper around `URLRequest` that carries a `requiresAuthentication` flag. This flag tells the authenticator whether it needs to attach credentials or pass the request through as-is.

The concrete implementation, `NetworkerImpl`, ties these together. When you call `perform(request:)`, it passes the request to the authenticator, executes the authenticated URL request via `URLSession`, and handles 401 responses by automatically retrying with a forced token refresh. If the retry also fails, it throws `NetworkError.notAuthenticated`.

### Setup

The typical setup involves creating an `AuthSessionProvider` (for token persistence), a `BearerAuthenticator` (for OAuth-style Bearer token auth), and then the `NetworkerImpl`:

```swift
let authenticator = BearerAuthenticator<MyAuthToken>(
    authSessionProvider: authSessionProvider,
    refreshUrl: URL(string: "https://api.example.com/auth/refresh"),
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    version: "1.0.0"
)

let network = NetworkerImpl(session: .shared, authenticator: authenticator)
```

The `BearerAuthenticator` is generic over your token type. It uses the `authSessionProvider` to read the current token, attaches it as a `Bearer` header, and if a request returns 401, it attempts to refresh the token by POSTing the refresh token to the `refreshUrl`. If the refresh succeeds, the new token is persisted via the auth session provider and the original request is retried. If it fails, the token is removed (effectively logging the user out) and an error is thrown.

### Requests

Every request in the framework is represented by the `Request` protocol, which exposes two properties: a `urlRequest` and a `requiresAuthentication` boolean. The framework provides two concrete types:

- **`AuthenticatedRequest`** — Sets `requiresAuthentication = true`. The authenticator will attach the Bearer token and handle refresh logic.
- **`PublicRequest`** — Sets `requiresAuthentication = false`. The authenticator passes the URL request through unmodified.

The framework also extends `URLRequest` with convenience initialisers and setters for common operations. The `URLRequest(url:versionNumber:)` initialiser automatically sets device type headers (`Device-Type: ios`, `Device-Type: macos`, etc.) and the app version, which is useful for API versioning:

```swift
var request = URLRequest(url: url, versionNumber: "1.0.0")
request.set(httpMethod: .post)
try request.set(httpBody: someEncodableObject) // Encodes to JSON and sets Content-Type
request.set(headerField: .authorization, value: .bearer(token: "abc"))
```

The `HTTPHeaderField` and `HTTPHeaderValue` types are stringly-typed wrappers that conform to `ExpressibleByStringLiteral`, so you can define custom headers easily while still getting type safety for common ones like `.authorization`, `.contentType`, and `.accept`.

### Global Headers and Request Logging

The `BearerAuthenticator` provides two optional callbacks that are applied to every request:

- **`globalHeadersProvider`** — A closure that receives the current auth token and returns a dictionary of additional headers. This is useful for headers that depend on the authenticated user (like a team ID or workspace identifier) and need to be present on every request.

- **`globalRequestLogger`** — A closure that receives every `Request` before it is sent. This is useful for debugging, analytics, or logging request URLs and methods during development.

Both are optional and `nil` by default.

### Error Handling

The networking layer uses two error types:

**`NetworkError`** is thrown by `NetworkerImpl.perform(request:)` and has two cases:
- `.notAuthenticated` — The request required authentication but the token was missing, expired, and could not be refreshed.
- `.urlError(URLError)` — A transport-level error occurred (no internet, timeout, DNS failure, etc.).

**`ServerError`** and **`ValidationError`** are not thrown by the network layer itself, but the framework provides parsing helpers on `Data` for extracting them from response bodies. This is designed around the Laravel API convention where a 422 response contains validation errors in a `{"errors": {"field": ["message"]}}` JSON structure:

```swift
let (data, response) = try await network.perform(request: request)

if response.statusCode == 422 {
    if let error = data.parseServerError(validationFields: MyField.self) {
        // error is a ValidationError<MyField> with per-field error messages
    }
}
```

`ValidationError` is generic over a `Field` type that you define as an enum of your form fields. The parser maps the JSON error keys to your enum cases, including support for nested dot-notation keys (e.g., `"address.street"` maps to the `address` field). If the response doesn't match the validation error format, it falls back to trying to parse a simple `ServerError` with a `message` field.

### Connectivity Monitoring

The `NetworkMonitor` protocol reports whether the device currently has a network path available. It exposes a Combine publisher for reactive observation and a synchronous getter for one-off checks:

```swift
public protocol NetworkMonitor {
    func isOnlinePublisher() -> AnyPublisher<Bool, Never>
    func isOnline() -> Bool
}
```

The concrete implementation, `NetworkMonitorImpl`, is backed by `NWPathMonitor`. It publishes on the main queue and de-duplicates consecutive identical states, so subscribers only fire on an actual online/offline transition. This is the natural trigger for retrying failed uploads or refreshing data when connectivity is restored:

```swift
let networkMonitor: NetworkMonitor = NetworkMonitorImpl()

// One-off check
if networkMonitor.isOnline() {
    try await sync()
}

// React to connectivity being restored
networkMonitor.isOnlinePublisher()
    .dropFirst()           // ignore the initial value
    .filter { $0 }         // only when coming back online
    .sink { _ in Task { await sync() } }
    .store(in: &cancellables)
```

Register a single instance in your dependency graph and inject it wherever connectivity matters. `NetworkMonitorImpl` is `Sendable` and cancels its underlying monitor on `deinit`.

---

## Authentication

### Auth Session Provider

The `AuthSessionProvider` protocol manages the lifecycle of authentication tokens. It provides methods to read, replace, and remove tokens, as well as a Combine publisher for observing token changes reactively.

The concrete implementation, `AuthSessionProviderImpl`, persists tokens to the Keychain via the `SecureStorage` protocol. Tokens are encoded as JSON using `Codable`, so any custom token type that conforms to `AuthTokenProtocol` (which requires `Codable` and `Equatable`) can be stored.

```swift
let authSessionProvider = AuthSessionProviderImpl(secureStorage: secureStorage)

// Store a token after login
authSessionProvider.replace(with: myToken)

// Read the current token (returns nil if not logged in)
let token: MyAuthToken? = authSessionProvider.current(as: MyAuthToken.self)

// Remove token on logout
authSessionProvider.remove()

// Observe auth state changes (useful for reactive UI updates)
authSessionProvider.authSessionPublisher()
    .sink { token in
        // nil means logged out, non-nil means logged in
    }
```

The `AuthSessionProvider` also manages a `deviceName` — a UUID string that uniquely identifies the device. This is generated automatically on first access and persisted in the Keychain. It is sent as part of the token refresh request body so the backend can track which device is requesting new tokens.

### Custom Auth Tokens

To define your own token type, conform to `AuthTokenProtocol`. The protocol requires `accessToken` and `refreshToken` string properties, plus `Codable`, `Equatable`, and `Sendable` conformance:

```swift
struct MyAuthToken: AuthTokenProtocol {
    let accessToken: String
    let refreshToken: String
    let userId: Int
    let permissions: [String]
}
```

The framework uses a type-erased `AnyAuthToken` internally to store tokens without knowing the concrete type. When you read a token back with `current(as: MyAuthToken.self)`, it attempts to cast the stored value back to your type. The `AnyAuthToken` also supports direct `Codable` encoding/decoding using the `token` and `refresh_token` JSON keys, so it can be decoded from a standard OAuth response without a custom token type.

---

## WebSockets

### Architecture

The `EventSocket` protocol provides a minimal interface for real-time event streaming: `subscribe(to:for:)` returns a Combine publisher of `SocketMessage` values, and `disconnect()` tears down the connection.

The concrete implementation, `PusherEventSocket`, wraps the Pusher WebSocket client. It handles connection management, authentication of private channels, automatic reconnection, and event binding. The class uses the same `Authenticator` protocol as the networking layer to authenticate WebSocket channel subscriptions, so private channels work out of the box with the same token management.

### How It Works

When you subscribe to a channel, the socket lazily connects to Pusher (if not already connected), subscribes to the specified channel, and begins forwarding events through the Combine publisher. Events are filtered by the channel and event names you specified. The publisher also emits built-in lifecycle events: `.connected`, `.disconnected`, and `.subscribed`.

If you pass an empty array for events, all events on that channel are forwarded. Multiple subscribers to the same channel share the same underlying Pusher subscription. When all subscribers cancel, the channel is automatically unsubscribed.

```swift
let socket = PusherEventSocket(
    authenticator: authenticator,
    endpoint: URL(string: "wss://ws.example.com")!,
    usesTLS: true,
    port: 443,
    versionNumber: "1.0.0",
    urlSession: .shared,
    pusherKey: "your-pusher-key",
    authenticationUrl: URL(string: "https://api.example.com/broadcasting/auth")
)

socket.subscribe(to: SocketChannel(rawValue: "orders"), for: [SocketEvent(rawValue: "updated")])
    .sink { message in
        // message.channel - which channel the event came from
        // message.event   - the event name
        // message.data    - optional [String: Any?] dictionary of event payload
    }
```

The `authenticationUrl` is optional. If `nil`, channels are treated as public and no authentication request is made. If provided, the socket authenticates private channels by sending a POST request (authenticated via the `Authenticator`) to that URL with the socket ID and channel name.

### Types

- **`SocketChannel`** — A simple wrapper around a raw string channel name. Conforms to `Equatable`, `Hashable`, and `Sendable`.
- **`SocketEvent`** — A simple wrapper around a raw string event name. Provides static constants for built-in events: `.connected`, `.disconnected`, `.subscribed`.
- **`SocketMessage`** — Contains the channel, event, and optional data dictionary for a received event.

---

## Storage

The framework provides three layers of local storage, each suited for different data types and security requirements.

### Key-Value Storage

`KeyValueStorage` wraps `UserDefaults` with type-safe keys and `Codable` support. It is intended for non-sensitive user preferences, feature flags, and small pieces of app state that should persist between launches.

Keys are defined as `KeyValueStorageKey` values. The type conforms to `ExpressibleByStringLiteral`, so you can define them as static constants on an extension:

```swift
extension KeyValueStorageKey {
    static let hasSeenOnboarding: KeyValueStorageKey = "hasSeenOnboarding"
    static let preferredTheme: KeyValueStorageKey = "preferredTheme"
}
```

The `KeyValueStorageImpl` concrete implementation wraps any `KeyValueStore` (a protocol that `UserDefaults` conforms to out of the box). It supports both raw string values and `Codable` objects:

```swift
let storage = KeyValueStorageImpl(
    store: UserDefaults.standard,
    encoder: JSONEncoder(),
    decoder: JSONDecoder()
)

// String values
storage.set("dark", forKey: .preferredTheme)
let theme: String? = storage.string(forKey: .preferredTheme)

// Codable values
storage.setValue(UserPreferences(...), forKey: .preferences)
let prefs: UserPreferences? = storage.value(forKey: .preferences)

// Removal
storage.remove(key: .hasSeenOnboarding)
```

### Secure Storage

`SecureStorage` wraps the Keychain for sensitive data like auth tokens, API keys, and encryption keys. Unlike `UserDefaults`, Keychain data is encrypted at rest and survives app reinstalls.

It works the same way as key-value storage but uses `SecureStorageKey` for its keys. The `SecureStorageImpl` concrete implementation wraps any `KeychainAccess`-conforming type:

```swift
extension SecureStorageKey {
    static let apiKey: SecureStorageKey = "apiKey"
}

let secureStorage = SecureStorageImpl(
    keychain: Keychain(service: "com.example.app"),
    encoder: JSONEncoder(),
    decoder: JSONDecoder()
)

try secureStorage.setString("secret-key", forKey: .apiKey)
let key: String? = secureStorage.string(forKey: .apiKey)

// Codable values
try secureStorage.setValue(myToken, forKey: .authToken)
let token: MyAuthToken? = secureStorage.value(forKey: .authToken)
```

Setting a value to `nil` removes it from the Keychain.

### Core Data (Legacy)

The framework includes a Combine-based wrapper around Core Data through the `PersistentStorage` protocol. It provides a fluent API for CRUD operations with predicate-based filtering. This is considered legacy and the GRDB implementation below is preferred for new projects.

The wrapper manages separate read and write contexts, handles context merging, and provides both synchronous and asynchronous entity access. Operations are expressed as chains of method calls:

```swift
let container = PersistentContainer(name: "Model")
let db = CoreDataPersistentStorage(container: container)

// Fetching with predicates
db.entity(MyEntity.self)
    .fetch()
    .suchThat { $0.property == 5 }
    .and { $0.name == "test" }
    .sorted(by: \.createdAt, ascending: false)
    .limit(10)
    .subscribe()

// Creating a new entity
db.entity(MyEntity.self)
    .create()
    .modify { entity, storage in
        entity.name = "New Item"
        // The second parameter gives access to the database for setting relationships
        entity.category = storage.entity(Category.self)
            .fetch()
            .suchThat { $0.name == "Default" }
            .perform()
            .first
    }
    .perform()
    .save()

// Updating (with optional creation if not found)
db.entity(MyEntity.self)
    .update(orCreate: true)
    .suchThat { $0.id == 1 }
    .modify { $0.name = "Updated" }
    .perform()
    .save()

// Deleting
db.entity(MyEntity.self)
    .delete()
    .suchThat { $0.id == 1 }
    .perform()
    .save()
```

The `suchThat`, `and`, `or`, and `excluding` methods build `NSPredicate` chains. The `modify` closure receives both the entity being modified and a `SynchronousStorage` reference for performing related lookups within the same transaction.

### GRDB (Local Database)

For new projects, the framework provides a GRDB-based SQLite database through `LocalDatabase` and `LocalDatabaseImpl`. GRDB offers better performance than Core Data for most use cases, a simpler mental model, and direct SQL access when needed.

`LocalDatabaseImpl` handles database file creation (in the Application Support directory), migration management, and pool initialisation. You define migrations by conforming to the `DatabaseMigration` protocol:

```swift
struct CreateUsersTable: DatabaseMigration {
    let name = "createUsersTable"

    func migrate(_ db: Database) throws {
        try db.create(table: "users") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("name", .text).notNull()
            t.column("email", .text).notNull().unique()
        }
    }
}

struct AddAvatarToUsers: DatabaseMigration {
    let name = "addAvatarToUsers"

    func migrate(_ db: Database) throws {
        try db.alter(table: "users") { t in
            t.add(column: "avatarUrl", .text)
        }
    }
}

let database = LocalDatabaseImpl(migrations: [
    CreateUsersTable(),
    AddAvatarToUsers()
])
```

Migrations are ordered by their position in the array and each migration runs only once. The `name` property serves as a unique identifier — once a migration has been applied, it is skipped on subsequent launches.

In debug builds, the database has `eraseDatabaseOnSchemaChange` enabled by default. This means if you change a migration that has already been applied (for example, adding a column to an existing migration instead of creating a new one), the database is erased and all migrations are re-run from scratch. This is convenient during development but would be destructive in production. Pass `enforceSchemaInDebug: true` to disable this behaviour.

The `database` property exposes a `DatabasePool` for concurrent reads and serialised writes:

```swift
// Write
try database.database.write { db in
    try db.execute(
        sql: "INSERT INTO users (name, email) VALUES (?, ?)",
        arguments: ["John", "john@example.com"]
    )
}

// Read
let users = try database.database.read { db in
    try Row.fetchAll(db, sql: "SELECT * FROM users")
}
```

For full GRDB capabilities (record types, query builders, observation), refer to the [GRDB documentation](https://github.com/groue/GRDB.swift).

---

## UI Components

### Navigation

The UI library provides a coordinator pattern implementation designed for SwiftUI's `NavigationStack`. It is split into two levels to support both simple and navigation-heavy use cases.

#### BaseCoordinator

`BaseCoordinator` is a `@MainActor` open class that provides the foundation: child coordinator management and an abstract `start()` method. It does not include any navigation state, making it suitable for coordinators that manage other coordinators (like an app-level coordinator that decides whether to show login or main flows) or coordinators that use presentation styles other than navigation stacks (sheets, full-screen covers).

The `start()` method has a `fatalError` implementation — subclasses must override it. Child coordinators are managed with `addChildCoordinator(_:)` and `removeChildCoordinator(_:)`, which maintain a strong reference array. It is the parent's responsibility to remove child coordinators when they are no longer needed to avoid retain cycles.

```swift
class AppCoordinator: BaseCoordinator {
    override func start() {
        let authCoordinator = AuthCoordinator()
        addChildCoordinator(authCoordinator)
        authCoordinator.start()
    }
}
```

#### NavigableCoordinator (iOS 17+)

`NavigableCoordinator<Route>` extends `BaseCoordinator` with a `NavigationPath` and type-safe navigation methods. It is generic over a `Route` type (any `Hashable` enum or struct) that represents the possible destinations within the coordinator's navigation stack.

The class is marked with `@Observable`, which means SwiftUI views automatically re-render when the `path` changes — there is no need for `@ObservedObject` or `@StateObject` wrappers.

It provides three navigation methods:
- **`push(_ route:)`** — Appends a route to the navigation path, pushing a new view onto the stack.
- **`pop()`** — Removes the last route from the path, navigating back one level. Does nothing if the path is already empty.
- **`popToRoot()`** — Replaces the entire path with an empty `NavigationPath`, returning to the root view.

```swift
enum HomeRoute: Hashable {
    case detail(id: Int)
    case settings
    case profile(userId: Int)
}

class HomeCoordinator: NavigableCoordinator<HomeRoute> {
    override func start() {
        // Perform any initial setup
    }

    func showDetail(id: Int) {
        push(.detail(id: id))
    }

    func showSettings() {
        push(.settings)
    }

    func goBack() {
        pop()
    }

    func returnHome() {
        popToRoot()
    }
}
```

#### AppNavigationStack (iOS 16+)

`AppNavigationStack` is a SwiftUI view that wraps `NavigationStack` with typed route-based destination resolution. It binds to a `NavigationPath` and uses `navigationDestination(for:)` internally to resolve routes to views.

It is designed to work with `NavigableCoordinator` but can be used independently with any `@Binding<NavigationPath>`:

```swift
struct HomeView: View {
    @State var coordinator = HomeCoordinator()

    var body: some View {
        AppNavigationStack(path: $coordinator.path) {
            // Root view
            VStack {
                Button("Show Detail") { coordinator.showDetail(id: 1) }
                Button("Settings") { coordinator.showSettings() }
            }
        } destination: { (route: HomeRoute) in
            // Map routes to destination views
            switch route {
            case .detail(let id):
                DetailView(id: id)
            case .settings:
                SettingsView()
            case .profile(let userId):
                ProfileView(userId: userId)
            }
        }
    }
}
```

### Alerts (SwiftUI)

The UI library provides two declarative, value-type alert systems so view models can request alerts without importing SwiftUI. Both are driven by an optional binding — set it to present, and the modifier clears it to `nil` on dismissal.

#### AppAlert

`AppAlert` describes a native SwiftUI alert (title, message, buttons with optional `.cancel`/`.destructive` roles). Present it with the `appAlert(_:)` modifier bound to an `AppAlert?`. Factory helpers cover the common cases (`ok`, `error`, `confirmation`). All button titles default to English literals — pass your own localised strings to override:

```swift
@State private var alert: AppAlert?

var body: some View {
    ContentView()
        .appAlert($alert)
}

// Informational
alert = .ok(title: "Saved", message: "Your changes were saved.")

// Error with an optional retry
alert = .error(error, title: "Upload Failed", retryTitle: "Retry", retryHandler: {
    Task { await retry() }
})

// Confirmation
alert = .confirmation(
    title: "Delete Item?",
    message: "This cannot be undone.",
    confirmTitle: "Delete",
    confirmRole: .destructive,
    onConfirm: { delete() }
)
```

`AppAlert` is `Foundation`-only, so it can be stored on a view model and exposed to the view via a `@Published` property.

#### AppInputAlert (iOS 17+)

SwiftUI's native alert cannot host text fields, so `AppInputAlert` renders a custom card (a glass effect on iOS 26, `.regularMaterial` below) with one or more input fields. Present it with `appInputAlert(_:)`. Factory helpers cover single text input, secure input, and multiple fields:

```swift
@State private var inputAlert: AppInputAlert?

var body: some View {
    ContentView()
        .appInputAlert($inputAlert)
}

// Single text field
inputAlert = .input(
    title: "Rename",
    placeholder: "New name",
    defaultValue: currentName,
    onConfirm: { newName in rename(to: newName) }
)

// Secure field
inputAlert = .secureInput(
    title: "Enter Password",
    placeholder: "Password",
    onConfirm: { password in unlock(with: password) }
)

// Multiple fields — the confirm handler receives one value per field, in order
inputAlert = .multiInput(
    title: "Credentials",
    fields: [
        .init(placeholder: "Email"),
        .init(placeholder: "Password", isSecure: true)
    ],
    onConfirm: { values in login(email: values[0], password: values[1]) }
)
```

Buttons are automatically ordered to match native iOS behaviour (cancel on the left for two buttons, destructive first / cancel last when stacked).

### SwiftUI Components

- **`StyledSegmentedControl` (iOS 13+)** — A `UIViewRepresentable` wrapper over `UISegmentedControl` that binds to any `Hashable & CaseIterable & Identifiable` value, giving full control over segment fonts and colours (which SwiftUI's `Picker(.segmented)` does not expose). Styling defaults to neutral system values; override them for your design system:

```swift
enum Filter: String, CaseIterable, Identifiable {
    case all, active, archived
    var id: Self { self }
}

@State private var filter: Filter = .all

StyledSegmentedControl(
    selection: $filter,
    normalTextColor: .white,
    selectedTextColor: .black,
    selectedTintColor: .white
) { $0.rawValue.capitalized }
.frame(height: 32)
```

### UIKit Components

The UI library also includes a collection of UIKit-based components for common patterns:

- **`AsyncImageView`** — A `UIView` subclass that loads and displays images asynchronously from `AsyncImage` sources (either local `AssetImage`/`LocalImage` or remote URLs). Manages loading, placeholder, and error states internally.
- **`IPAsyncImageView`** — A `UIViewRepresentable` wrapper that makes `AsyncImageView` available in SwiftUI.
- **`MonthCalendarView`** — A full-featured month calendar built on `UICollectionView` with `UICollectionViewCompositionalLayout`. Supports custom day cell configurations (`MonthCalendarDayContentConfiguration`), month labels with various formats, and day-of-week headers.
- **`SearchBarView`** — A configurable search bar with customisable styling.
- **`SeparatorView` / `TextSeparatorView`** — Thin horizontal line separators, with an optional centred text label variant.
- **`LoadingCell` / `RetryCell`** — `UICollectionViewCell` subclasses for displaying loading spinners and retry buttons in collection views.
- **`EmptyStateView`** — A generic view for displaying empty state messages with an optional action control.
- **`StackView`** — A generic `UIView` subclass that manages a typed array of child views in a stack layout.
- **`UIViewController.showAlert(...)`** — A convenience for presenting a `UIAlertController` with a dismiss button and an optional retry action. Useful from coordinators or hosting controllers that are still UIKit:

```swift
showAlert(
    title: "Something Went Wrong",
    message: error.localizedDescription,
    retryHandler: { self.retry() }
)
```

### SwiftUI View Extensions

- **Conditional modifiers** — `View.if(_:transform:)` applies a modifier only when a condition is true, avoiding the need for `Group`/`if-else` blocks.
- **Transform helpers** — `View.apply { }` returns the result of an arbitrary (possibly type-changing) transform inline in a modifier chain; `ToolbarContent.apply { }` does the same for toolbar content. `View.configure { }` runs a side-effecting block and returns the view unchanged.
- **Type erasure** — `View.toAnyView()` wraps the view in `AnyView`, handy when a property or closure must return a single concrete view type.
- **Keyboard observation** — `View.onKeyboardAppear` and `View.onKeyboardDisappear` attach Combine-based keyboard notification listeners.
- **Corner radius** — The `CornerRadius` enum provides named corner radius values for consistent spacing.
- **Margins** — `CGFloat.Margin` provides named margin/spacing constants.

### State Management

- **`PagingState`** — An enum representing the state of a paginated list: `.idle`, `.loading`, `.loaded`, `.error(ErrorWrapper)`. Useful for driving paginated collection view or list UIs.
- **`RetryState`** — An enum for retry-capable operations: `.idle`, `.loading`, `.error(ErrorWrapper)`.
- **`ErrorWrapper`** — A `Sendable` struct that wraps an `Error` with `Equatable` conformance (by comparing `localizedDescription`), making it usable in SwiftUI state.
- **`TimeLock`** — A simple rate-limiter struct. Call `lock()` to set the current time, then `unlock()` throws if not enough time has passed since the last lock. Useful for preventing rapid duplicate API calls or button taps.

---

## Utilities

Small, dependency-free helpers that most apps end up re-implementing.

- **`String.isBlank`** (`AppsPlusData`) — `true` when the string is empty or contains only whitespace and newlines. Prefer this over `isEmpty` when validating trimmed user input:

```swift
guard !name.isBlank else { return }
```

---

## Testing

The `AppsPlusTesting` library provides two categories of test support:

### Mock Implementations

Every major protocol in `AppsPlusData` has a corresponding mock class. These mocks store calls and allow you to configure return values, making it easy to write isolated unit tests:

| Mock | Mocks Protocol | Purpose |
|------|---------------|---------|
| `MockSecureStorage` | `SecureStorage` | In-memory keychain replacement |
| `MockKeyValueStorage` | `KeyValueStorage` | In-memory user defaults replacement |
| `MockPersistentStorage` | `PersistentStorage` | In-memory database replacement |
| `MockAuthSessionProvider` | `AuthSessionProvider` | Controllable auth state |
| `MockEventSocket` | `EventSocket` | Controllable WebSocket events |

### Property-Based Test Generators

The library includes SwiftCheck `Arbitrary` conformances for generating random test data. These are useful for property-based testing where you want to verify that your code works for any valid input, not just hand-picked examples:

- **Primitives**: `Data`, `Date`, `DateInterval`, `String`, `URL`, `UUID`
- **Framework types**: `Page`, `ValidationError`, `MockCodable`
- **System types**: `UNAuthorizationStatus`, `LABiometryType`
- **Combinators**: `ArbitraryPair` for generating pairs of related random values

---

## Swift Concurrency

All public protocols and types are annotated for Swift strict concurrency checking. This means you can use the framework in projects with complete concurrency checking enabled (Swift 6 language mode) without warnings at the call site.

The annotations follow these principles:

- **Value types** (structs, enums) with all-Sendable stored properties conform to `Sendable`. The compiler verifies this is actually safe.
- **Protocols** that are expected to be passed across concurrency boundaries (like `Network`, `SecureStorage`, `KeyValueStorage`, `AuthSessionProvider`, `Authenticator`, `EventSocket`) inherit from `Sendable`. This requires all conforming types to also be `Sendable`.
- **Classes with internal synchronisation** (like `BearerAuthenticator`, `PusherEventSocket`, `CoreDataPersistentStorage`) are marked `@unchecked Sendable`. This tells the compiler to trust that the class manages its own thread safety. The "unchecked" means the compiler does not verify this — it is a contract from the developer.
- **UI types** that must be accessed from the main thread (`Coordinator`, `BaseCoordinator`, `NavigableCoordinator`) are marked `@MainActor`.
- **`NavigableCoordinator`** uses the `@Observable` macro for automatic SwiftUI integration.
The framework compiles cleanly under both Swift 5.9 (with strict concurrency warnings) and Swift 6 language mode.

