import UIKit

public class TonConnectRetProcessor {
    public init() {}
}

public extension TonConnectRetProcessor {
    func process(
        ret: TonConnectRet?,
        manifest: TonConnectManifest
    ) {
        guard let ret else { return }
        
        let url: URL?
        switch ret {
        case .back:
            url = manifest.url
        case .none:
            return
        case .url(let string):
            url = URL(string: string)
        }
        
        if let url {
            Task { @MainActor in
                UIApplication.shared.open(url)
            }
        }
    }
}
