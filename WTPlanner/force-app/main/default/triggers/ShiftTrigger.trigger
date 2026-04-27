trigger ShiftTrigger on Shift__c (after insert, after update, after delete, after undelete) {
    ShiftTriggerHandler handler = new ShiftTriggerHandler();
    handler.run();
}
