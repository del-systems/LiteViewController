public final class OpaqueLiteViewController<Dependencies, Context> {
	public init<View>(from initializer: @escaping (Dependencies, Context) -> View) where View: SystemView {
		liteView = initializer
	}

	let liteView: (Dependencies, Context) -> SystemView
}
