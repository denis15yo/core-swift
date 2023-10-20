//
//  SettingsAssembly.swift
//
//
//  Created by Grigory on 3.10.23..
//

import Foundation

final class SettingsAssembly {
    
    private var settingsController: SettingsController?
    
    func settingsController(keeperController: KeeperController) -> SettingsController {
        guard let settingsController = settingsController else {
            let settingsController = SettingsControllerImplementation(keeperController: keeperController)
            self.settingsController = settingsController
            return settingsController
        }
        return settingsController
    }
    
    func logoutController(cacheURL: URL,
                          keychainGroup: String,
                          keeperInfoService: KeeperInfoService,
                          fileManager: FileManager,
                          keychainManager: KeychainManager) -> LogoutController {
        LogoutController(
            cacheURL: cacheURL,
            keychainGroup: keychainGroup,
            keeperInfoService: keeperInfoService,
            fileManager: fileManager,
            keychainManager: keychainManager
        )
    }
}
