//
//  ViewController.swift
//  DynamicToss
//
//  Created by Jason Linscombe on 2/7/19.
//  Copyright © 2019 givemesomecoffee.com. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var redSquare: UIView!
    @IBOutlet weak var blueSquare: UIView!
    
    private var originalBounds = CGRect.zero
    private var originalCenter = CGPoint.zero
    
    private var animator: UIDynamicAnimator!
    private var attachmentBehavior: UIAttachmentBehavior!
    private var pushBehavior: UIPushBehavior!
    private var itemBehavior: UIDynamicItemBehavior!
    
    // ThrowingThreshhold indicates how fast the view must be moving in order to have the view continue moving (versus immediately returning to its original spot). ThrowingVelocityPadding is a magic constant that affects how fast or slow the toss should be (this was chosen by trial and error).
    let ThrowingThreshold: CGFloat = 1000
    let ThrowingVelocityPadding: CGFloat = 35
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animator = UIDynamicAnimator(referenceView: view)
        originalBounds = imageView.bounds
        originalCenter = imageView.center
    }

    func resetDemo() {
        animator.removeAllBehaviors()
        
        UIView.animate(withDuration: 0.45) {
            self.imageView.bounds = self.originalBounds
            self.imageView.center = self.originalCenter
            self.imageView.transform = .identity
        }
    }
    
    @IBAction func handleAttachmentGesture(sender: UIPanGestureRecognizer) {
        let location = sender.location(in: self.view)
        let boxLocation = sender.location(in: self.imageView)
        
        switch sender.state {
        case .began:
            // make the image view track your finger when you make a pan gesture.
            
            print("Your touch start position is \(location)")
            print("Start location in image is \(boxLocation)")
            
            // 1 First you remove any existing animation behaviors that might be hanging around.
            animator.removeAllBehaviors()
            
            // 2 Next, you create a UIAttachmentBehavior that attaches the the point inside the image view where the user taps to an anchor point (which happens to be the exact same point). Later on, you will change the anchor point, which will cause the image view to move. Attaching an anchor point to a view is like installing an invisible rod that connects the anchor point to a fixed attachment position on the view.
            let centerOffset = UIOffset(horizontal: boxLocation.x - imageView.bounds.midX,
                                        vertical: boxLocation.y - imageView.bounds.midY)
            attachmentBehavior = UIAttachmentBehavior(item: imageView,
                                                      offsetFromCenter: centerOffset, attachedToAnchor: location)
            
            // 3 Update the red square to indicate the anchor point, and the blue square to indicate the point inside the image view that it is attached to. When the gesture starts, these will be the same point.
            redSquare.center = attachmentBehavior.anchorPoint
            blueSquare.center = location
            
            // 4 Add this behavior to the animator to make it take effect.
            animator.addBehavior(attachmentBehavior)
            
            
        case .ended:
            print("Your touch end position is \(location)")
            print("End location in image is \(boxLocation)")
            
            animator.removeAllBehaviors()
            
            // 1 Ask the gesture for the velocity of the drag.
            // Using velocity and your old friend the Pythagorean theorem, you compute the magnitude of the velocity — which is the hypotenuse of the triangle formed from the x direction velocity and the y direction velocity.
            let velocity = sender.velocity(in: view)
            let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
            
            if magnitude > ThrowingThreshold {
                // 2 Assuming the gesture magnitude exceeds your minimum threshold set up for the action, you set up a push behavior.
                // A push behavior applies a force to the specified items. In this case, it’s an instantaneous force against the image.
                // The desired direction is composed of the x and y velocities converted to a vector that gives the directional portion. Once you have the push behavior set up, you add it to the animation sequence.
                let pushBehavior = UIPushBehavior(items: [imageView], mode: .instantaneous)
                pushBehavior.pushDirection = CGVector(dx: velocity.x / 10, dy: velocity.y / 10)
                pushBehavior.magnitude = magnitude / ThrowingVelocityPadding
                
                self.pushBehavior = pushBehavior
                animator.addBehavior(pushBehavior)
                
                // 3 This section sets up some rotations to make the image “fly away”.
                // Some of this depends on how close to the edge your finger is when it initiates the gesture.
                // Play around with the values here and watch how the movements change the effects. The values used give a nice, flowing rotation with a cool spinning effect!
                let angle = Int(arc4random_uniform(20)) - 10
                
                itemBehavior = UIDynamicItemBehavior(items: [imageView])
                itemBehavior.friction = 0.2
                itemBehavior.allowsRotation = true
                itemBehavior.addAngularVelocity(CGFloat(angle), for: imageView)
                animator.addBehavior(itemBehavior)
                
                // 4 After a specified interval of time, the animation resets by sending the image back to its destination, so it zips off and returns to the screen — just like a ball bouncing off a wall!
                let delay = DispatchTime.now() + .seconds(5)
                DispatchQueue.main.asyncAfter(deadline: delay) {
                    self.resetDemo()
                }
            } else {
                // return the view back to its original position when you’re done dragging
                resetDemo()
            }
        default:
            // tell the anchor point itself to follow your finger. The default case handles the gesture update calls as the user pans around. The code here simply aligns the anchor point and red square to the finger’s current position. When the user’s finger moves, the gesture recognizer calls this method to update the anchor point to follow the touch. In addition, the animator automatically updates the view to follow the anchor point.
            attachmentBehavior.anchorPoint = sender.location(in: view)
            redSquare.center = attachmentBehavior.anchorPoint
            
        }
    }

}

