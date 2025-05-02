public extension String {
    func isTonAddressBounceable() -> Bool {
        uppercased().starts(with: "EQ")
    }
}
