trigger SessionTypeTrigger on Session_Type__c (before delete) {
    DeleteProtectionHandler.preventSessionTypeDeletion(Trigger.old);
}
