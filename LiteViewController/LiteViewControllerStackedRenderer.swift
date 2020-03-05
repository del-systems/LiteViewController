import UIKit

private struct ViewAndContext {
	var obj: AnyObject
	var view: SystemView
	var context: InternalContext
}

public final class LiteViewControllerStackedRenderer: UIViewController {
	public struct Actions {
		public func present<View>(liteViewController: @escaping (Actions, LiteViewControllerContext) -> View) where View: SystemView {
			_present(OpaqueLiteViewController(from: liteViewController))
		}

		public func dismiss() {
			_dismiss()
		}

		fileprivate var _present: (OpaqueLiteViewController<Actions, LiteViewControllerContext>) -> Void
		fileprivate var _dismiss: () -> Void
	}

	override public func loadView() {
		view = UIView()
		view.clipsToBounds = false
		view.backgroundColor = .black
	}

	private func present(concrete: OpaqueLiteViewController<Actions, LiteViewControllerContext>) {
		let context = InternalContext(from: self)

		let actions = Actions(
			_present: present(concrete:),
			_dismiss: dismissAction(for: concrete)
		)

		let liteView = concrete.liteView(actions, context)
		insert(liteView: liteView)
		_stack.append(.init(obj: concrete, view: liteView, context: context))
		context._callOnAppear()
		transform(view: liteView, usingAnchorPoint: .init(x: 0.5, y: 0.0)) { $0.translatedBy(x: 0, y: view.bounds.height) }

		animate(onComplete: {
			self._stack.dropLast().last.flatMap { vc in
				vc.context._callOnDisappear()
				vc.view.removeFromSuperview()
			}
		}) {
			liteView.transform = .identity
			self.view.setNeedsLayout()
		}
	}

	public func present<View>(liteViewController: @escaping (Actions, LiteViewControllerContext) -> View) where View: SystemView {
		present(concrete: OpaqueLiteViewController(from: liteViewController))
	}

	private func dismissAction(for concrete: OpaqueLiteViewController<Actions, LiteViewControllerContext>) -> () -> Void {
		return { [weak self, weak concrete] in
			guard let self = self else { return }
			guard let concrete = concrete else { return }

			var startedDismissing = false
			self._stack.removeAll { vc in
				if vc.obj === concrete { startedDismissing = true }
				guard startedDismissing else { return false }

				vc.context._attachedVCs.forEach { $0.removeFromParent() }
				vc.context._callOnDisappear()
				self.animate(onComplete: vc.view.removeFromSuperview) {
					self.transform(view: vc.view, usingAnchorPoint: .init(x: 0.5, y: 0)) { $0.translatedBy(x: 0, y: self.view.bounds.height) }
				}

				return true
			}
			self._stack.last.flatMap { vc in
				self.insert(liteView: vc.view)
				self.view.insertSubview(vc.view, at: 0)
				vc.context._callOnAppear()
			}

			self.view.setNeedsLayout()
		}
	}

	private func transform(view: UIView, usingAnchorPoint newAnchorPoint: CGPoint, transform: (CGAffineTransform) -> CGAffineTransform) {
		let preparedTransform = CGAffineTransform
			.identity
			.translatedBy(x: (newAnchorPoint.x - 0.5) * view.bounds.width, y: (newAnchorPoint.y - 0.5) * view.bounds.height)

		view.transform = transform(preparedTransform)
			.translatedBy(x: (0.5 - newAnchorPoint.x) * view.bounds.width, y: (0.5 - newAnchorPoint.y) * view.bounds.height)
	}

	private func insert(liteView: SystemView) {
		view.addSubview(liteView)
		liteView.translatesAutoresizingMaskIntoConstraints = false
		liteView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
		liteView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
		liteView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
		liteView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
	}

	private func animate(onComplete: @escaping () -> Void = { }, _ animationBlock: @escaping () -> Void) {
		UIView.animate(
			withDuration: 0.5,
			delay: 0,
			usingSpringWithDamping: 1,
			initialSpringVelocity: 0,
			options: [],
			animations: animationBlock,
			completion: { _ in onComplete() })
	}

	private var _stack: [ViewAndContext] = []
}
