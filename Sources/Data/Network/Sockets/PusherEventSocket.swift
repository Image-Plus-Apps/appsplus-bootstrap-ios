#if canImport(Foundation) && canImport(Combine) && canImport(PusherSwift)

import Foundation
import Combine
import PusherSwift

public class PusherEventSocket: EventSocket, PusherDelegate, @unchecked Sendable {

    class AuthRequestBuilder: AuthRequestBuilderProtocol {
        private var request: URLRequest

        init(request: URLRequest) {
            self.request = request
        }

        func requestFor(socketID: String, channelName: String) -> URLRequest? {
            request.httpBody = "socket_id=\(socketID)&channel_name=\(channelName)".data(using: .utf8)
            return request
        }
    }

    class PusherBinder {

        private let pusher: Pusher
        private var subscribedChannels = [PusherChannel]()

        var delegate: PusherDelegate? {
            get {
                return pusher.delegate
            }
            set {
                pusher.delegate = newValue
            }
        }

        var connection: ConnectionState {
            return pusher.connection.connectionState
        }

        required init(key: String, options: PusherClientOptions) {
            self.pusher = Pusher(key: key, options: options)
        }

        func connect() {
            pusher.connect()
        }

        func subscribe(_ channelName: String) {
            let subscribedChannel = subscribedChannels.first {
                $0.name == channelName &&
                $0.subscribed
            }
            guard subscribedChannel == nil else {
                return
            }
            subscribedChannels.append(pusher.subscribe(channelName))
        }

        func unsubscribe(_ channelName: String) {
            pusher.unsubscribe(channelName)
            subscribedChannels.removeAll { $0.name == channelName }
        }

        func bind(eventCallback: @escaping (PusherEvent) -> Void) {
            pusher.bind(eventCallback: eventCallback)
        }

        func unbindAll() {
            pusher.unbindAll()
        }

        func disconnect() {
            pusher.disconnect()
        }
    }

    private var pusher: PusherBinder?
    private var authenticator: Authenticator
    private let urlSession: URLSession
    private let endpoint: URL
    private let port: Int
    private let usesTLS: Bool
    private let versionNumber: String
    private let pusherKey: String
    private let authenticationUrl: URL?
    private let eventsPublisher = PassthroughSubject<SocketMessage, Never>()
    private var subscribedChannels = [SocketChannel]()
    private var subscriptions = [SocketChannel: AnyPublisher<SocketMessage, Never>]()
    private var cancellables = Set<AnyCancellable>()

    public init(
        authenticator: Authenticator,
        endpoint: URL,
        usesTLS: Bool,
        port: Int,
        versionNumber: String,
        urlSession: URLSession,
        pusherKey: String,
        authenticationUrl: URL?
    ) {
        self.authenticator = authenticator
        self.urlSession = urlSession
        self.endpoint = endpoint
        self.versionNumber = versionNumber
        self.pusherKey = pusherKey
        self.port = port
        self.usesTLS = usesTLS
        self.authenticationUrl = authenticationUrl
    }

    deinit {
        disconnect()
    }
    
    func classForPusherBinder() -> PusherBinder.Type {
        PusherBinder.self
    }

    func buildAuthenticationRequest() -> AnyPublisher<URLRequest?, AuthenticatorError> {
        guard let authenticationUrl = authenticationUrl else {
            return Just(nil)
                .setFailureType(to: AuthenticatorError.self)
                .eraseToAnyPublisher()
        }

        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(AuthenticatorError.noAuthSession))
                return
            }
            
            Task {
                do {
                    var request = URLRequest(url: authenticationUrl, versionNumber: self.versionNumber)
                    request.set(httpMethod: .post)

                    let authenticatedRequest = try await self.authenticator.authenticate(
                        request: AuthenticatedRequest(urlRequest: request),
                        forceRefresh: false,
                        urlSession: self.urlSession
                    )
                    promise(.success(authenticatedRequest))
                } catch let error as AuthenticatorError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(AuthenticatorError.noAuthSession)) // Handle unexpected errors
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func attemptConnection() -> AnyPublisher<PusherBinder, EventSocketError> {
        if let pusher = pusher, pusher.connection == .connected {
            return Just(pusher)
                .setFailureType(to: EventSocketError.self)
                .eraseToAnyPublisher()
        }
        return buildAuthenticationRequest()
            .mapError { _ in EventSocketError.unknown }
            .map { [unowned self] in
                 initializePusher($0)
            }
            .map {
                $0.connect()
                return $0
            }
            .eraseToAnyPublisher()
    }

    private func initializePusher(_ authenticationRequest: URLRequest?) -> PusherBinder {
        let authMethod: AuthMethod
        if let authenticationRequest = authenticationRequest {
            authMethod = AuthMethod.authRequestBuilder(
                authRequestBuilder: AuthRequestBuilder(request: authenticationRequest)
            )
        } else {
            authMethod = .noMethod
        }
        let options = PusherClientOptions(
            authMethod: authMethod,
            attemptToReturnJSONObject: false,
            autoReconnect: true,
            host: .host(endpoint.host!),
            port: port,
            useTLS: usesTLS,
            activityTimeout: 60
        )

        pusher = classForPusherBinder().init(key: pusherKey, options: options)
        pusher!.delegate = self
        return pusher!
    }

    public func disconnect() {
        pusher?.disconnect()
        pusher = nil
    }

    public func subscribe(to channel: SocketChannel, for events: [SocketEvent]) -> AnyPublisher<SocketMessage, Never> {
        let filter: (SocketMessage) -> Bool = {
            return $0.channel == channel &&
            events.isEmpty ? true : (
                events + [.connected, .disconnected, .subscribed]
            ).contains($0.event)
        }
        
        if let publisher = subscriptions[channel] {
            return publisher
                .share()
                .filter(filter)
                .eraseToAnyPublisher()
        }
        
        let publisher = eventsPublisher
            .handleEvents(
                receiveCancel: {
                    DispatchQueue.main.async { [weak self] in
                        self?.unsubscribe(fromChannel: channel)
                    }
                },
                receiveRequest: { [weak self] demand in
                    guard demand > 0,
                          let self = self else { return }
                    self.attemptConnection()
                        .map {
                            $0.subscribe(channel.rawValue)
                        }
                        .sink { _ in } receiveValue: {_ in}
                        .store(in: &self.cancellables)
                }
            )
            .eraseToAnyPublisher()
        
        subscriptions[channel] = publisher
        
        return publisher
            .share()
            .filter(filter)
            .eraseToAnyPublisher()
    }

    private func unsubscribe(fromChannel channel: SocketChannel) {
        pusher?.unsubscribe(channel.rawValue)
        subscriptions[channel] = nil
    }

    public func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?) {
        print("Failed to subscribe to channel: \(name)")
    }

    public func subscribedToChannel(name: String) {
        eventsPublisher.send(
            .init(
                channel: SocketChannel(rawValue: name),
                event: .subscribed,
                data: nil
            )
        )
    }

    public func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        switch new {
        case .disconnected:
            eventsPublisher.send(.init(channel: nil, event: .disconnected, data: nil))
        case .connected:
            eventsPublisher.send(.init(channel: nil, event: .connected, data: nil))
            pusher?.unbindAll()
            pusher?.bind(
                eventCallback: { [unowned self] (item: PusherEvent) in
                    guard let channelName = item.channelName else {
                        return
                    }
                    let channel = SocketChannel(rawValue: channelName)
                    let event = SocketEvent(rawValue: item.eventName)

                    let data = item.data
                        .flatMap { $0.data(using: .utf8) }
                        .flatMap { try? JSONSerialization.jsonObject(with: $0, options: []) }
                        .flatMap { $0 as? [String: Any?] }

                    eventsPublisher.send(.init(channel: channel, event: event, data: data))
                }
            )
        default:
            break
        }
    }
}

#endif
