import SwiftUI
import UnityHubStorage
import UnityHubCommonViews

struct SearchTokenSuggestions: View {
	@Cache(InstallationCache.self) private var installations

	private let tokens: [SearchToken]

	init(_ tokens: [SearchToken]) {
		self.tokens = tokens
	}

	var body: some View {
		if installations.installations.count > 1 {
			if
				installations.installations.contains(where: { $0.version?.isLTS ?? false }),
				!tokens.contains(where: { $0.kind == .lts })
			{
				Text("LTS").searchCompletion(
					SearchToken.lts(true)
				)
			}

			if
				installations.installations.contains(where: { $0.version?.isPrerelease ?? false }),
				!tokens.contains(where: { $0.kind == .prerelease })
			{
				Text("Prerelease").searchCompletion(
					SearchToken.prerelease(true)
				)
			}

			let uniqueMajorVersions = installations.uniqueMajorVersions
			if
				uniqueMajorVersions.count > 1,
				!tokens.contains(where: { $0.kind == .majorVersion })
			{
				Text("Major Version").searchCompletion(
					SearchToken.majorVersion(uniqueMajorVersions[uniqueMajorVersions.count - 1])
				)
			}
		}
	}
}