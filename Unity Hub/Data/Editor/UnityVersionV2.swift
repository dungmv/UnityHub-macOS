import Foundation

struct UnityVersionV2: Identifiable, CustomStringConvertible {
	var major: UInt16
	var minor: UInt16
	var patch: UInt16
	var channel: String
	var iteration: UInt16
	
	var versionString: String
	
	var description: String { "\(major).\(minor).\(patch)\(channel)\(iteration)" }
	var id: String { description }

	//init(_ string: String) {
	//
	//}
}

extension UnityVersionV2 {
	enum Channel: String {
		case alpha = "a"
		case beta = "b"
		case final = "f"
		case patch = "p"
		case china = "c"
	}
}
