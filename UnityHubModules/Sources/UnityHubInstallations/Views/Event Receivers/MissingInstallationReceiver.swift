import SwiftUI
import UnityHubCommon

struct MissingInstallationReceiver: View {
	@State private var isPresentingDialog: Bool = false
	@State private var url: URL? = nil

	var body: some View {
		EmptyView()
			.onReceive(Event.missingInstallation, perform: receiveEvent)
			.confirmationDialog(
				"Missing Project",
				isPresented: $isPresentingDialog,
				actions: {
					Button(role: .cancel, action: removeInstallation, label: Label.remove)
					Button(action: locateInstallation, label: Label.locate)
				},
				message: {
					Text("The installation cannot be found.  It may have been moved or deleted.")
				}
			)
			.dialogSeverity(.critical)
	}
}

// MARK: - Functions

private extension MissingInstallationReceiver {
	func receiveEvent(value: URL) {
		url = value
		isPresentingDialog = true
	}

	func removeInstallation() {
		let url = consumeValue()
		Event.removeInstallation(url)
	}

	func locateInstallation() {
		let url = consumeValue()
		Event.locateInstallation(.replace(url))
	}

	func consumeValue() -> URL {
		guard let url else {
			preconditionFailure(missingObject: URL.self)
		}
		self.url = nil
		return url
	}
}