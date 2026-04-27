trigger SessionTrigger on Session__c (before delete) {
    DeleteProtectionHandler.preventSessionDeletion(Trigger.old);
}
