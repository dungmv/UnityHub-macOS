import OSLog
import SwiftUI
import UnityHubCommon
import UnityHubStorage

struct AddProjectList: View {
	var body: some View {
		Menu(
			content: {
				Button.createProject()
				Button.locateProject()
			},
			label: Label.add
		)
	}
}
