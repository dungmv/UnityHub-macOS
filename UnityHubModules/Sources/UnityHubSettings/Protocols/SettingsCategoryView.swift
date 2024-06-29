import SwiftUI
import UnityHubStorage

protocol SettingsCategoryView: View {
	associatedtype Content: View
	associatedtype Label: View
	associatedtype Model: SettingsFile

	var model: Model { get set }

	@ViewBuilder func makeContent() -> Content

	@ViewBuilder func makeLabel() -> Label
}

// MARK: - Default Implementation

extension SettingsCategoryView {
	var body: some View {
		Form(content: makeContent)
			.scrollDisabled(true)
			.onChange(of: model, model.save)
			.onDisappear(perform: model.save)
			.tabItem(makeLabel)
			.tag(Model.category)
	}
}
