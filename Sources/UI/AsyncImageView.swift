#if canImport(UIKit) && canImport(Combine) && canImport(Foundation) && (os(iOS) || os(tvOS) || os(macOS))

import UIKit
import Combine
import CoreGraphics
import Foundation

public struct AssetImage {
    let image: UIImage
    let isCached: Bool
    let originalRequest: AsyncImage
    
    public init(image: UIImage, isCached: Bool, originalRequest: AsyncImage) {
        self.image = image
        self.isCached = isCached
        self.originalRequest = originalRequest
    }
}

@available(iOS 13.0, tvOS 13.0, *)
public protocol AsyncImage {
    var key: String? { get }
    func equals(_ image: AsyncImage) -> Bool
    func imagePublisher() -> AnyPublisher<AssetImage, URLError>
    func hash(into hasher: inout Hasher)
    func clearCache()
}

extension AsyncImage {
    public func clearCache() {
        guard let key = key else {
            return
        }
        ImageCache.shared.clearCache(for: key)
    }
}

@available(iOS 13.0, tvOS 13.0, *)
extension AsyncImage where Self: Equatable {
    
    public func equals(_ image: AsyncImage) -> Bool {
        guard let image = image as? Self else {
            return false
        }
        return image == self
    }
    
}

@available(iOS 13.0, tvOS 13.0, *)
extension Optional where Wrapped == AsyncImage {
    
    public func equals(_ image: AsyncImage?) -> Bool {
        if case .none = self, case .none = image {
            return true
        } else if case .some(let lhs) = self,
                  case .some(let rhs) = image {
            return lhs.equals(rhs)
        }
        return false
    }
    
}

@available(iOS 13.0, tvOS 13.0, *)
extension URL: AsyncImage {
    
    public var key: String? {
        absoluteString
    }
    
    public func imagePublisher() -> AnyPublisher<AssetImage, URLError> {
        if let cachedResult = URLCache.shared.cachedResponse(for: URLRequest(url: self)),
           let image = UIImage(data: cachedResult.data) {
            return Just(AssetImage(image: image, isCached: true, originalRequest: self))
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: self)
            .tryMap { data, _ in
                guard let image = UIImage(data: data) else {
                    throw URLError(.cannotDecodeRawData)
                }
                return AssetImage(image: image, isCached: false, originalRequest: self)
            }
            .mapError { $0 as? URLError ?? URLError(.badServerResponse) }
            .eraseToAnyPublisher()
    }
    
}

@available(iOS 13.0, tvOS 13.0, *)
public struct LocalImage: AsyncImage, Equatable, Hashable {
    
    public let path: String
    public let compressRate: CGFloat
    
    public init(path: String, compressRate: CGFloat = 0.8) {
        self.path = path
        self.compressRate = compressRate
    }
    
    public var key: String? {
        path
    }
    
    public func imagePublisher() -> AnyPublisher<AssetImage, URLError> {
        return Future<AssetImage, URLError> { promise in
            DispatchQueue.global(qos: .userInteractive).async {
                guard let docDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
                    promise(.failure(URLError(URLError.fileDoesNotExist)))
                    return
                }
                
                let fileUrl = URL(fileURLWithPath: docDirectory.appendingPathComponent(path).path)
                
                guard let data = try? Data(contentsOf: fileUrl),
                      let image = UIImage(data: data),
                      let compressedImageData = image.jpegData(compressionQuality: compressRate),
                      let compressedImage = UIImage(data: compressedImageData) else {
                    promise(.failure(URLError(URLError.fileDoesNotExist)))
                    return
                }
                
                promise(.success(AssetImage(image: compressedImage, isCached: false, originalRequest: self)))
                
            }
        }.eraseToAnyPublisher()
    }
    
    public func completeUrl() -> AnyPublisher<URL, URLError> {
        return Future<URL, URLError> { promise in
            guard let docDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
                promise(.failure(URLError(URLError.fileDoesNotExist)))
                return
            }
            
            promise(.success(URL(fileURLWithPath: docDirectory.appendingPathComponent(path).path)))
        }.eraseToAnyPublisher()
    }
}

@available(iOS 13.0, tvOS 13.0, *)
extension UIImage: AsyncImage {
    
    public var key: String? {
        nil
    }
    
    public func imagePublisher() -> AnyPublisher<AssetImage, URLError> {
        Just(AssetImage(image: self, isCached: true, originalRequest: self))
            .setFailureType(to: URLError.self)
            .eraseToAnyPublisher()
    }
    
}

@available(iOS 13.0, tvOS 13.0, *)
public class AsyncImageView: UIView {
    
    public enum State {
        case idle
        case loading
        case success
        case failed
    }
    
    private var setNeedsFetchImage = false
    /**
     Setting this to true will show the loading animation
     when an image is being fetched to display.
     Defaults to `false`
     */
    public var shouldShowLoadingAnimation = false
    public var image: AsyncImage? {
        didSet {
            if oldValue.equals(image) != true {
                setNeedsFetchImage = true
                setNeedsLayout()
            }
        }
    }
    public var cornerRadius: CornerRadius = .value(0) {
        didSet {
            if oldValue != cornerRadius {
                setNeedsLayout()
            }
        }
    }
    public override var bounds: CGRect {
        didSet {
            if oldValue != bounds {
                setNeedsFetchImage = true
                setNeedsLayout()
            }
        }
    }
    
    @Published public private(set) var state = State.idle
    
    private var cancellables = Set<AnyCancellable>()
    private var imageCancellable: AnyCancellable?
    private let imageView = UIImageView()
    private let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    private let resizeQueue = DispatchQueue(label: Bundle.main.bundleIdentifier ?? "" + ".graphics.resize")
    public var shouldAutoResize = true
    
    public override var contentMode: UIView.ContentMode {
        didSet {
            imageView.contentMode = contentMode
            if oldValue != contentMode {
                setNeedsFetchImage = true
                setNeedsLayout()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        contentMode = .scaleAspectFill
        setUp(imageView: imageView)
        setUp(activityIndicatorView: activityIndicatorView)
        addSubview(imageView)
        addSubview(activityIndicatorView)
        setUpConstraints()
        bindState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindState() {
        $state
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                switch $0 {
                case .loading:
                    showLoadingAnimation()
                default:
                    hideLoadingAnimation()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setUp(imageView: UIImageView) {
        imageView.isUserInteractionEnabled = false
        imageView.contentMode = contentMode
    }
    
    private func setUp(activityIndicatorView: UIActivityIndicatorView) {
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setUpConstraints() {
        imageView.pinConstraints(to: self)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
    
    /**
     Should only be called by the instance itself and never by another object. Setting a new url will call this function indirectly.
     */
    private func fetchImage() {
        cancel()
        guard let image = image, window != nil else {
            return
        }
        setNeedsFetchImage = false
        state = .loading
        imageCancellable = image.imagePublisher()
            .flatMap { [unowned self] (assetImage: AssetImage) -> AnyPublisher<AssetImage, URLError> in
                self.resizeImage(assetImage)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [unowned self] completion in
                switch completion {
                case .finished:
                    state = .success
                case .failure:
                    state = .failed
                }
                imageCancellable = nil
            }, receiveValue: { [unowned self] result in
                imageView.image = result.image
                if result.isCached {
                    imageView.alpha = 1
                } else {
                    UIView.animate(withDuration: 0.3) { [weak self] in
                        self?.imageView.alpha = 1
                    }
                }
            })
    }
    
    public func retry() {
        fetchImage()
    }
    
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            cancel()
            setNeedsFetchImage = true
        } else {
            setNeedsLayout()
        }
    }
    
    private func cancel() {
        imageCancellable = nil
        imageView.image = nil
        imageView.alpha = 0
        state = .idle
    }
    
    private func showLoadingAnimation() {
        guard shouldShowLoadingAnimation, !activityIndicatorView.isAnimating else { return }
        activityIndicatorView.startAnimating()
    }
    
    private func hideLoadingAnimation() {
        activityIndicatorView.stopAnimating()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if setNeedsFetchImage {
            fetchImage()
        }
        apply(cornerRadius: cornerRadius)
    }
    
    private func resizeImage<ImageError: Error>(_ asset: AssetImage) -> AnyPublisher<AssetImage, ImageError> {
        guard shouldAutoResize else {
            return Just(asset).setFailureType(to: ImageError.self).eraseToAnyPublisher()
        }
        return Future { [weak self] completion in
            DispatchQueue.main.async {
                guard let self = self else {
                    completion(.success(asset))
                    return
                }
                let size = self.bounds.size
                let contentMode = self.contentMode
                
                if self.validImage(asset.image, forSize: size, contentMode: contentMode) {
                    completion(.success(asset))
                } else if let cachedImage = ImageCache.shared.image(for: asset.originalRequest, size: size, contentMode: contentMode) {
                    completion(.success(AssetImage(image: cachedImage, isCached: asset.isCached, originalRequest: asset.originalRequest)))
                } else {
                    self.resizeQueue.async {
                        let resizedImage = self.redrawImage(asset.image, toFit: size, contentMode: contentMode)
                        ImageCache.shared.setResizedImage(resizedImage, for: asset.originalRequest, at: size, contentMode: contentMode)
                        completion(.success(AssetImage(image: resizedImage, isCached: asset.isCached, originalRequest: asset.originalRequest)))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private func validImage(_ image: UIImage, forSize size: CGSize, contentMode: UIView.ContentMode) -> Bool {
        switch contentMode {
        case .scaleAspectFit:
            return image.size.width <= size.width && image.size.height <= size.height
        default:
            return image.size.width <= size.width || image.size.height <= size.height
        }
    }
    
    private func redrawImage(_ image: UIImage, toFit size: CGSize, contentMode: UIView.ContentMode) -> UIImage {
        image.atSize(size, contentMode: contentMode)
    }
}

private class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private var keys = [NSString]()
    private let queue = DispatchQueue(label: "IP-CACHE-KEYS-QUEUE", attributes: .concurrent)
    
    private func key(for identifier: String, size: CGSize, contentMode: UIView.ContentMode) -> NSString {
        "\(identifier)|\(round(size.width))|\(round(size.height))|\(contentMode.rawValue)" as NSString
    }
    
    func image(for image: AsyncImage, size: CGSize, contentMode: UIView.ContentMode) -> UIImage? {
        if let identifier = image.key {
            return cache.object(forKey: key(for: identifier, size: size, contentMode: contentMode))
        } else {
            return nil
        }
    }
    
    func clearCache(for identifier: String) {
        var validKeys: [NSString]!
        
        queue.sync {
            validKeys = keys.filter { $0.contains(identifier) }
            validKeys.forEach {
                cache.removeObject(forKey: $0)
            }
        }
        
        queue.async(flags: .barrier) { [weak self] in
            self?.keys.removeAll(where: { validKeys.contains($0) })
        }
    }
    
    func setResizedImage(_ image: UIImage, for originalImage: AsyncImage, at size: CGSize, contentMode: UIView.ContentMode) {
        if let identifier = originalImage.key {
            let key = key(for: identifier, size: size, contentMode: contentMode)
            cache.setObject(image, forKey: key)
            queue.async(flags: .barrier) { [weak self] in
                self?.keys.append(key)
            }
        }
    }
}


#endif
