public enum TonConnectRet {
    case back
    case none
    case url(String)
    
    public init(string: String) {
        switch string {
        case "back":
            self = .back
        case "none":
            self = .none
        default:
            self = .url(string)
        }
    }
}
