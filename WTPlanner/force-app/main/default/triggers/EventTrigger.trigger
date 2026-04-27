trigger EventTrigger on Event__c (before delete) {
    DeleteProtectionHandler.preventEventDeletion(Trigger.old);
}
