import Foundation

enum MoveDirection: String {
    case forward = "forward"
    case backward = "backward"
    case left = "left"
    case right = "right"
}

enum LookDirection: String {
    case up = "up"
    case down = "down"
    case left = "left"
    case right = "right"
    case center = "center"
}

enum ArmSide: String {
    case left = "left"
    case right = "right"
}

enum ArmPosition: String {
    case up = "up"
    case down = "down"
}