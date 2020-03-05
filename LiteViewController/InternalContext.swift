final class InternalContext: LiteViewControllerContext {
	private var _onAppear: [Listener] = []
	private var _onDissapear: [Listener] = []
	var _attachedVCs: Set<SystemViewController> = []
	private var _attach: (SystemViewController) -> Void = { _ in }
	private var _detach: (SystemViewController) -> Void = { _ in }
	let systemViewController: SystemViewController

	init(from: SystemViewController) {
		systemViewController = from

		_attach = { [unowned self] in

			guard self._attachedVCs.insert($0).inserted else { return }
			self.systemViewController.addChild($0)
		}
		_detach = { [unowned self] in
			self._attachedVCs.remove($0)
			$0.removeFromParent()
		}
	}

	func attach(viewController: SystemViewController) {
		_attach(viewController)
	}

	func detach(viewController: SystemViewController) {
		_detach(viewController)
	}

	func onViewAppear(listener: @escaping Listener) {
		_onAppear.append(listener)
	}

	func onViewDisappear(listener: @escaping Listener) {
		_onDissapear.append(listener)
	}

	func _callOnAppear() {
		_onAppear.forEach { $0() }
	}

	func _callOnDisappear() {
		_onDissapear.forEach { $0() }
	}
}
