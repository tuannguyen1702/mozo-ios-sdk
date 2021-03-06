//
//  CoreInteractor.swift
//  MozoSDK
//
//  Created by Hoang Nguyen on 9/6/18.
//

import Foundation
import PromiseKit

class CoreInteractor: NSObject {
    var output: CoreInteractorOutput?
    
    let anonManager: AnonManager
    let apiManager: ApiManager
    let userDataManager: UserDataManager
    
    init(anonManager: AnonManager, apiManager : ApiManager, userDataManager: UserDataManager) {
        self.anonManager = anonManager
        self.apiManager = apiManager
        self.userDataManager = userDataManager
    }
    
    private func getUserProfile() -> Promise<Void> {
        return Promise { seal in
            _ = apiManager.getUserProfile().done { (userProfile) in
                    let user = UserDTO(id: userProfile.userId, profile: userProfile)
                    SessionStoreManager.saveCurrentUser(user: user)
                
                    let userModel = UserModel(id: userProfile.userId, mnemonic: nil, pin: nil, wallets: nil)
                    if self.userDataManager.addNewUser(userModel) == true {
                        seal.resolve(nil)
                    }
                }.catch({ (err) in
                    //TODO: Handle HTTP load failed for user profile
                })
        }
    }
}

extension CoreInteractor: CoreInteractorInput {
    func checkForAuthentication(module: Module) {
        if AccessTokenManager.getAccessToken() != nil {
            if SessionStoreManager.loadCurrentUser() != nil {
                // Check wallet
                if let wallet = SessionStoreManager.loadCurrentUser()?.profile?.walletInfo, wallet.encryptSeedPhrase != nil {
                    output?.finishedCheckAuthentication(keepGoing: false, module: module)
                } else {
                    // Re-authenicate, manage wallet
                    output?.continueWithWallet(module)
                }
                // TODO: Handle update local user profile data
            } else {
                print("😎 Load user info.")
                _ = getUserProfile().done({ () in
                    self.output?.finishedCheckAuthentication(keepGoing: false, module: module)
                }).catch({ (err) in
                    //TODO: No user profile, can not continue with any module
                })
            }
        } else {
            output?.finishedCheckAuthentication(keepGoing: true, module: module)
        }
    }
    
    func handleAferAuth(accessToken: String?) {
        AccessTokenManager.saveToken(accessToken)
        // TODO: Start all background services including web socket
        downloadConvenienceDataAndStoreAtLocal()
        anonManager.linkCoinFromAnonymousToCurrentUser()
        _ = getUserProfile().done({ () in
            self.output?.finishedHandleAferAuth()
        }).catch({ (err) in
            //TODO: Handle case unable to load user profile
        })
    }
    
    func notifyAuthSuccessForAllObservers() {
        NotificationCenter.default.post(name: .didAuthenticationSuccessWithMozo, object: nil)
    }
    
    func notifyLogoutForAllObservers() {
        NotificationCenter.default.post(name: .didLogoutFromMozo, object: nil)
    }
}

extension CoreInteractor: CoreInteractorService {
    func loadBalanceInfo() -> Promise<DetailInfoDisplayItem> {
        return Promise { seal in
            // TODO: Check authen and authorization first
            if let userObj = SessionStoreManager.loadCurrentUser() {
                if let address = userObj.profile?.walletInfo?.offchainAddress {
                    print("Address used to load balance: \(address)")
                    _ = apiManager.getTokenInfoFromAddress(address)
                        .done { (tokenInfo) in
                            let item = DetailInfoDisplayItem(tokenInfo: tokenInfo)
                            if SessionStoreManager.exchangeRateInfo == nil {
                                _ = self.apiManager.getExchangeRateInfo(currencyType: .KRW).done({ (data) in
                                    SessionStoreManager.exchangeRateInfo = data
                                    seal.fulfill(item)
                                }).catch({ (error) in
                                    seal.fulfill(item)
                                })
                            } else {
                                seal.fulfill(item)
                            }
                        }.catch({ (err) in
                            seal.reject(err)
                        })
                }
            } else {
                seal.reject(SystemError.noAuthen)
            }
        }
    }
    
    func downloadConvenienceDataAndStoreAtLocal() {
        if AccessTokenManager.getAccessToken() != nil {
            downloadAddressBookAndStoreAtLocal()
            downloadExchangeRateInfoAndStoreAtLocal()
        }
    }
    
    func downloadAddressBookAndStoreAtLocal() {
        print("😎 Load address book list.")
        _ = apiManager.getListAddressBook().done({ (list) in
            SessionStoreManager.addressBookList = list
        }).catch({ (error) in
            //TODO: Handle case unable to load address book list
        })
    }
    
    func downloadExchangeRateInfoAndStoreAtLocal() {
        print("😎 Load exchange rate data.")
        _ = apiManager.getExchangeRateInfo(currencyType: .KRW).done({ (data) in
            SessionStoreManager.exchangeRateInfo = data
        }).catch({ (error) in
            //TODO: Handle case unable to load exchange rate info
        })
    }
}
