//
//  PersistenceController+History.swift
//  FefeReader
//
//  Created by Olaf Neumann on 25.12.24.
//

import CoreData
import CloudKit

extension PersistenceController {
    /**
     Handle .NSPersistentStoreRemoteChange notifications.
     Process persistent history to merge relevant changes to the context, and deduplicate entries if necessary.
     */
    @objc
    func storeRemoteChange(_ notification: Notification) {
        guard let storeUUID = notification.userInfo?[NSStoreUUIDKey] as? String,
              storeIdentifiers.contains(storeUUID) else {
            appPrint("\(#function): Ignore a store remote Change notification because of no valid storeUUID.")
            return
        }
        processHistoryAsynchronously(storeUUID: storeUUID)
    }
    
    /**
     Handle the container's event changed notifications (NSPersistentCloudKitContainer.eventChangedNotification).
     */
    @objc
    func containerEventChanged(_ notification: Notification) {
        guard let value = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey],
              let event = value as? NSPersistentCloudKitContainer.Event else {
            appPrint("\(#function): Failed to retrieve the container event from notification.userInfo.")
            return
        }
        if event.error != nil {
            appPrint("\(#function): Received a persistent CloudKit container event changed notification.\n\(event)")
        }
    }
    
    /**
     Process persistent history, posting any relevant transactions to the current view.
     This method processes the new history since the last history token, and is simply a fetch if there is no new history.
     */
    private func processHistoryAsynchronously(storeUUID: String) {
        historyQueue.addOperation {
            let taskContext = self.persistentContainer.newTaskContext()
            taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            taskContext.performAndWait {
                self.performHistoryProcessing(storeUUID: storeUUID, performingContext: taskContext)
            }
        }
    }
    
    private func performHistoryProcessing(storeUUID: String, performingContext: NSManagedObjectContext) {
        /**
         Fetch history received from outside the app since the last timestamp
         */
        //#-code-listing(fetchHistory)
        let lastHistoryToken = historyToken(with: storeUUID)
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
        let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!
        historyFetchRequest.predicate = NSPredicate(format: "author != %@", "app")
        request.fetchRequest = historyFetchRequest
        
        if let store = getStore(for: storeUUID) {
            request.affectedStores = [store]
        }
        //#-end-code-listing
        
        let result = (try? performingContext.execute(request)) as? NSPersistentHistoryResult
        guard let transactions = result?.result as? [NSPersistentHistoryTransaction] else {
            return
        }
        // print("\(#function): Processing transactions: \(transactions.count).")
        
        /**
         Post transactions so observers can update UI if necessary, even when transactions is empty,
         because when a share changes, Core Data triggers a store remote change notification with no transaction.
         */
        let userInfo: [String: Any] = [UserInfoKey.storeUUID: storeUUID, UserInfoKey.transactions: transactions]
        NotificationCenter.default.post(name: .fefeStoreDidChange, object: self, userInfo: userInfo)
        /**
         Update the history token using the last transaction. The last transaction has the latest token.
         */
        if let newToken = transactions.last?.token {
            updateHistoryToken(with: storeUUID, newToken: newToken)
        }
        
        /**
         Limit to the private store so only owners can deduplicate the tags. Owners have full access to the private database, and so
         don't need to worry about the permissions.
         */
        guard !transactions.isEmpty, storeUUID == privatePersistentStore.identifier else {
            return
        }
        
        /**
         Deduplicate the new tags.
         Only tags that are not shared or have the same share are deduplicated.
         */
        var newObjectIDs = [NSManagedObjectID]()
        let entityName = BlogEntry.entity().name
        
        for transaction in transactions where transaction.changes != nil {
            for change in transaction.changes! {
                if change.changedObjectID.entity.name == entityName && change.changeType == .insert {
                    newObjectIDs.append(change.changedObjectID)
                }
            }
        }
        if !newObjectIDs.isEmpty {
            deduplicateAndWait(blogEntryObjectIDs: newObjectIDs)
        }
    }
    
    /**
     Track the last history tokens for the stores.
     The historyQueue reads the token when executing operations, and updates it after completing the processing.
     Access this user default from the history queue.
     */
    private func historyToken(with storeUUID: String) -> NSPersistentHistoryToken? {
        let key = "HistoryToken" + storeUUID
        if let data = UserDefaults.standard.data(forKey: key) {
            return  try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
        }
        return nil
    }
    
    private func updateHistoryToken(with storeUUID: String, newToken: NSPersistentHistoryToken) {
        let key = "HistoryToken" + storeUUID
        let data = try? NSKeyedArchiver.archivedData(withRootObject: newToken, requiringSecureCoding: true)
        UserDefaults.standard.set(data, forKey: key)
    }
}
