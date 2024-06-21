public enum SettingsCategory: UInt8 {
	case general
	case projects
	case installations
	case locations
}

// MARK: - Hashable

extension SettingsCategory: Hashable { }

// MARK: - Identifiable

extension SettingsCategory: Identifiable {
	public var id: RawValue { rawValue }
}

// MARK: -

extension SettingsCategory {
	var fileName: String {
		switch self {
			case .general: "general"
			case .projects: "projects"
			case .installations: "installations"
			case .locations: "locations"
		}
	}
}