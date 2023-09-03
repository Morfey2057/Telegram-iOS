import Foundation
import UIKit
import Display
import ContextUI
import ComponentFlow

private let gradientBlueStart: UIColor = UIColor(red: 0/255, green: 135/255, blue: 249/255, alpha: 1)
private let gradientBlueEnd: UIColor = UIColor(red: 86/255, green: 198/255, blue: 255/255, alpha: 1)
private let gradientGrayStart: UIColor = UIColor(red: 173/255, green: 181/255, blue: 190/255, alpha: 1)
private let gradientGrayEnd: UIColor = UIColor(red: 217/255, green: 216/255, blue: 223/255, alpha: 1)
private let revealBlueIndicator: UIColor = UIColor(red: 73/255, green: 176/255, blue: 251/255, alpha: 1)
private let revealGrayIndicator: UIColor = UIColor(red: 202/255, green: 206/255, blue: 211/255, alpha: 1)

private let swipeDownForArchive = "Swipe down for archive"
private let releaseForArchive = "Release for archive"

class ScrollIndicator: UIView {

	var image = generateTintedImage(image: UIImage(bundleImageName: "Chat/OverscrollArrow"), color: gradientGrayStart)

	lazy var imageView: UIImageView = {
		let imageView = UIImageView()
		imageView.image = image
		return imageView
	}()

	lazy var imageIndicator: UIView = {
		let view = UIView()
		view.backgroundColor = .white
		return view
	}()

	override func layoutSubviews() {
		super.layoutSubviews()

		layer.cornerRadius = frame.size.width / 2.0

		addSubview(imageIndicator)
		imageIndicator.addSubview(imageView)


		let imageIndicatorSize = frame.width
		imageIndicator.frame = CGRect(
			x: 0,
			y: frame.height - imageIndicatorSize,
			width: imageIndicatorSize,
			height: imageIndicatorSize
		)

		let imageSize = imageIndicatorSize * 0.65
		imageView.frame = CGRect(
			x: (imageIndicatorSize - imageSize) / 2,
			y: (imageIndicatorSize - imageSize) / 2,
			width: imageSize,
			height: imageSize
		)

		imageIndicator.layer.cornerRadius = imageIndicator.layer.bounds.width / 2
		imageIndicator.clipsToBounds = false
	}
}


class OverlayControllerView: UIView {

	private var revealOverlayState: RevealOverlayAnimation = .collapsing
	var revealCompletion: (() -> Void)?
	lazy var blueGradient: CAGradientLayer = {
		let gradient = CAGradientLayer()
		gradient.colors = [
			gradientBlueStart.cgColor,
			gradientBlueEnd.cgColor
		]
		gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
		gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
		gradient.locations = [0, 1]
		return gradient
	}()

	lazy var grayGradient: CAGradientLayer = {
		let gradient = CAGradientLayer()
		gradient.colors = [
			gradientGrayStart.cgColor,
			gradientGrayEnd.cgColor
		]
		gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
		gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
		gradient.locations = [0, 1]
		return gradient
	}()

	lazy var textLabel: UILabel = {
		let label = UILabel()
		label.textColor = .white
		label.textAlignment = .center
		label.text = swipeDownForArchive
		label.font = .systemFont(ofSize: 17, weight: .semibold)
		return label
	}()

	lazy var blueScrollIndicator: ScrollIndicator = ScrollIndicator()

	lazy var grayScrollIndicator: ScrollIndicator = ScrollIndicator()

	enum RevealOverlayAnimation: Equatable {
		case collapsing
		case expanding
		case reveal(triggerFrame: CGRect)
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		layer.addSublayer(blueGradient)
		layer.addSublayer(grayGradient)
		blueGradient.addSublayer(blueScrollIndicator.layer)
		grayGradient.addSublayer(grayScrollIndicator.layer)
		blueScrollIndicator.image = generateTintedImage(image: UIImage(bundleImageName: "Chat/OverscrollArrow"), color: gradientBlueStart)
		blueScrollIndicator.backgroundColor = revealBlueIndicator
		grayScrollIndicator.backgroundColor = revealGrayIndicator
		animateRotation(animation: .collapsing)
		addSubview(textLabel)
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		blueGradient.frame = bounds
		blueGradient.removeAllAnimations()
		grayGradient.frame = bounds
		grayGradient.removeAllAnimations()
		grayScrollIndicator.frame = CGRect(x: 0.07 * frame.width, y: frame.height * 0.06, width: 0.06 * frame.width, height: frame.height * 0.88)
		blueScrollIndicator.frame = CGRect(x: 0.07 * frame.width, y: frame.height * 0.06, width: 0.06 * frame.width, height: frame.height * 0.88)
		textLabel.frame = CGRect(x: 0, y: frame.height - 10 - 16, width: frame.width, height: 16)
		textLabel.layer.zPosition = 2
	}

	let animationDuration: CGFloat = 0.175
	func update(with animation: RevealOverlayAnimation) {
		if animation == revealOverlayState { return }
	
		let triggerFrame = convert(blueScrollIndicator.imageIndicator.frame, from: blueScrollIndicator)

		self.revealOverlayState = animation
		switch revealOverlayState {
		case .collapsing:
			circleAnim(blueGradient, duration: animationDuration, inAnimation: false, trigger: triggerFrame)
			animateRotation(animation: .collapsing)
			textLabel.text = swipeDownForArchive
			textLabel.layer.animatePosition(from: CGPoint(x: textLabel.layer.frame.width, y: textLabel.layer.position.y), to: textLabel.layer.position, duration: animationDuration)

		case .expanding:
			circleAnim(blueGradient, duration: animationDuration, inAnimation: true, trigger: triggerFrame)
			animateRotation(animation: .expanding)
			textLabel.text = releaseForArchive
			textLabel.layer.animatePosition(from: CGPoint(x: -textLabel.layer.frame.width, y: textLabel.layer.position.y),
											to: textLabel.layer.position, duration: animationDuration)
		case .reveal(let triggerFrame):
			circleAnim(blueGradient, duration: animationDuration, inAnimation: false, trigger: triggerFrame)
			textLabel.layer.animatePosition(from: textLabel.layer.position,
											to: CGPoint(x: -textLabel.layer.frame.width, y: textLabel.layer.position.y), duration: animationDuration)
		}
	}

	func animateRotation(animation: RevealOverlayAnimation) {
		let angle: CGFloat = {
			switch animation {
			case .collapsing: return 180
			case .expanding: return -360
			case .reveal: return 0
			}
		}()
		UIView.animate(withDuration: animationDuration, delay: 0) {
			self.blueScrollIndicator.imageView.transform = CGAffineTransform(rotationAngle: angle * .pi / 180)
			self.grayScrollIndicator.imageView.transform = CGAffineTransform(rotationAngle: angle * .pi / 180)

		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func circleAnim(_ layer: CALayer, duration: CFTimeInterval, inAnimation: Bool, trigger: CGRect) {
		let maskDiameter = CGFloat(sqrtf(powf(Float(layer.bounds.width), 2) + powf(Float(layer.bounds.height), 2))) * 2
		let mask = CAShapeLayer()
		let animationId = "path"

		let filledRect: CGRect = CGRect(x: 0, y: 0, width: maskDiameter, height: maskDiameter)
		let nonFilled: CGRect = CGRect(
			x: (maskDiameter) / 2, y: (maskDiameter) / 2,
			width: trigger.width, height: trigger.height
		)

		let toRect = inAnimation ? filledRect : nonFilled
		let fromRect = inAnimation ? nonFilled : filledRect
		let fromCornerRadius = inAnimation ? trigger.width / 2 : maskDiameter / 2
		let toCornerRadius = inAnimation ? maskDiameter / 2 : trigger.width / 2

		mask.path = UIBezierPath(roundedRect: fromRect, cornerRadius: fromCornerRadius).cgPath
		mask.position = CGPoint(x: (trigger.minX - maskDiameter / 2), y: (trigger.minY - maskDiameter / 2))
		layer.mask = mask

		let animation = CABasicAnimation(keyPath: animationId)
		animation.duration = duration
		animation.fillMode = .forwards
		animation.isRemovedOnCompletion = false

		let newPath = UIBezierPath(roundedRect: toRect, cornerRadius: toCornerRadius).cgPath

		animation.fromValue = mask.path
		animation.toValue = newPath
		animation.delegate = self

		mask.add(animation, forKey: animationId)
	}
}

extension OverlayControllerView: CAAnimationDelegate {
	func animationDidStart(_ anim: CAAnimation) {
		switch revealOverlayState {
		case .collapsing: return
		case .expanding:
			blueGradient.zPosition = 1
			grayGradient.zPosition = 0
		case .reveal: grayGradient.removeFromSuperlayer()
		}
	}
	func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		switch revealOverlayState {
		case .collapsing:
			blueGradient.zPosition = 0
			grayGradient.zPosition = 1
		case .expanding:
			blueGradient.zPosition = 1
		case .reveal:
			blueGradient.removeFromSuperlayer()
			revealCompletion?()
		}
	}
}
