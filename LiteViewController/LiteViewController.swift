import UIKit

public typealias SystemView = UIView
public typealias SystemViewController = UIViewController

public protocol LiteViewControllerContext {
	typealias Listener = () -> Void

	func attach(viewController: SystemViewController)
	func detach(viewController: SystemViewController)
	func onViewAppear(listener: @escaping Listener)
	func onViewDisappear(listener: @escaping Listener)
	var systemViewController: SystemViewController { get }
}
