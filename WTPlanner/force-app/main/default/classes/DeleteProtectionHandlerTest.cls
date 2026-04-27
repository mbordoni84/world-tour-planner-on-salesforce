@isTest
private class DeleteProtectionHandlerTest {

    @testSetup
    static void setup() {
        Event__c event = new Event__c(Name = 'Test Event');
        insert event;

        Session_Type__c sessionType = new Session_Type__c(
            Name = 'Booth',
            Event__c = event.Id
        );
        insert sessionType;

        Session__c session = new Session__c(
            Name = 'Test Session',
            Session_Type__c = sessionType.Id,
            Location__c = 'Expo Hall'
        );
        insert session;

        Shift__c shift = new Shift__c(
            Session__c = session.Id,
            Start_Time__c = Time.newInstance(9, 0, 0, 0),
            End_Time__c = Time.newInstance(11, 0, 0, 0)
        );
        insert shift;
    }

    @isTest
    static void testDeleteSession_WithAssignedShift_Blocked() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];
        shift.User__c = UserInfo.getUserId();
        update shift;

        Session__c session = [SELECT Id FROM Session__c LIMIT 1];

        Test.startTest();
        try {
            delete session;
            System.assert(false, 'Should have thrown exception');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cannot delete'), 'Should block deletion');
        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteSession_NoAssignments_Allowed() {
        Session__c session = [SELECT Id FROM Session__c LIMIT 1];

        Test.startTest();
        delete session;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Session__c], 'Session should be deleted');
    }

    @isTest
    static void testDeleteSessionType_WithAssignedShift_Blocked() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];
        shift.User__c = UserInfo.getUserId();
        update shift;

        Session_Type__c st = [SELECT Id FROM Session_Type__c LIMIT 1];

        Test.startTest();
        try {
            delete st;
            System.assert(false, 'Should have thrown exception');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cannot delete'), 'Should block deletion');
        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteSessionType_NoAssignments_Allowed() {
        Session_Type__c st = [SELECT Id FROM Session_Type__c LIMIT 1];

        Test.startTest();
        delete st;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Session_Type__c], 'Session Type should be deleted');
    }

    @isTest
    static void testDeleteEvent_WithAssignedShift_Blocked() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];
        shift.User__c = UserInfo.getUserId();
        update shift;

        Event__c event = [SELECT Id FROM Event__c LIMIT 1];

        Test.startTest();
        try {
            delete event;
            System.assert(false, 'Should have thrown exception');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cannot delete'), 'Should block deletion');
        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteEvent_NoAssignments_Allowed() {
        Event__c event = [SELECT Id FROM Event__c LIMIT 1];

        Test.startTest();
        delete event;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Event__c], 'Event should be deleted');
    }
}
