//
//  PhysicsServiceProtocol.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 3/9/25.
//

import Foundation

protocol PhysicsServiceProtocol {
    func rollBallWithRandomPosition(maxY: CGFloat, completion: @escaping (CGPoint) -> Void)
    func moveBall(to position: CGPoint)
    func resetBall()
}
