//
//  CoreInteractorIO.swift
//  MozoSDK
//
//  Created by Hoang Nguyen on 9/13/18.
//

import Foundation
import PromiseKit

protocol CoreInteractorInput {
    func checkForAuthentication(module: Module)
    func handleAferAuth(accessToken: String?)
    func notifyAuthSuccessForAllObservers()
    func notifyLogoutForAllObservers()
}

protocol CoreInteractorOutput {
    func finishedCheckAuthentication(keepGoing: Bool, module: Module)
    func continueWithWallet(_ callbackModule: Module)
    func finishedHandleAferAuth()
}

protocol CoreInteractorService {
    func loadBalanceInfo() -> Promise<DetailInfoDisplayItem>
}
