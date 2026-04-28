import Foundation

enum SocketChannelError: Error, Sendable {
    case unknownError
    case failedToSubscribe(channel: SocketChannel, error: NSError?)
}

extension SocketChannelError: LocalizedError {
    
    var errorDescription: String? {
        if case .failedToSubscribe(channel: _, error: let error) = self,
           let error = error {
            return error.localizedDescription
        } else {
            return NSError(domain: "socket.channel.error", code: -99, userInfo: nil).localizedDescription
        }
    }
    
}
