enum SidebarItem: UInt8 {
	case projects
	case installations
	case resources
}

// MARK: - Hashable

extension SidebarItem: Hashable { }

// MARK: - Identifiable

extension SidebarItem: Identifiable {
	var id: RawValue { rawValue }
}

// MARK: - CaseIterable

extension SidebarItem: CaseIterable { }

// MARK: - CustomStringConvertible

extension SidebarItem: CustomStringConvertible {
	var description: String {
		switch self {
			case .projects: "Projects"
			case .installations: "Installations"
			case .resources: "Resources"
		}
	}
}

// MARK: -

extension SidebarItem {
	var systemImageName: String {
		switch self {
			case .projects: "cube"
			case .installations: "square.and.arrow.down"
			case .resources: "info.circle"
		}
	}
}
