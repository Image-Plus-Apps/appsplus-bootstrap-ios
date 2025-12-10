#if canImport(SwiftUI)
import SwiftUI

public struct IPAsyncImage: Identifiable {
    
    public let image: AsyncImage?
    public var uuid: String
    public var id: String {
        return image?.key ?? uuid
    }
    
    public init(uuid: String = UUID().uuidString, image: AppsPlusUI.AsyncImage?) {
        self.uuid = uuid
        self.image = image
    }
    
}

public struct IPAsyncImageView: UIViewRepresentable {
    
    public var image: IPAsyncImage
    public let contentMode: UIView.ContentMode
    
    public init(image: IPAsyncImage, contentMode: UIView.ContentMode) {
        self.image = image
        self.contentMode = contentMode
    }
    
    public func makeUIView(context: Context) -> AsyncImageView {
        let view = AsyncImageView()
        view.image = image.image
        view.contentMode = contentMode
        return view
    }
    
    public func updateUIView(_ uiView: AsyncImageView, context: Context) {
        uiView.image = image.image
        uiView.contentMode = contentMode
    }
    
}
#endif
