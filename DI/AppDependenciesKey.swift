//
//  AppDependenciesKey.swift
//  Agil10.0
//
//  Created by Christiane Roth on 13.12.25.
//

import SwiftUI

struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue = AppDependencies.shared
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
