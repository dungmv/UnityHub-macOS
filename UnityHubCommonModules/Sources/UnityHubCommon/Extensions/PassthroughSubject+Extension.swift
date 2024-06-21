import Combine

public extension PassthroughSubject where Failure == Never {
	func callAsFunction(_ input: Output) {
		send(input)
	}
}

public extension PassthroughSubject<Void, Never> {
	func callAsFunction() {
		send()
	}
}
