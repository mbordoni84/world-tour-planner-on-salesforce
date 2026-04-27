@isTest
private class ShiftTriggerHandlerTest {

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

        List<Shift__c> shifts = new List<Shift__c>{
            new Shift__c(
                Session__c = session.Id,
                Start_Time__c = Time.newInstance(9, 0, 0, 0),
                End_Time__c = Time.newInstance(11, 0, 0, 0)
            ),
            new Shift__c(
                Session__c = session.Id,
                Start_Time__c = Time.newInstance(10, 0, 0, 0),
                End_Time__c = Time.newInstance(12, 0, 0, 0)
            ),
            new Shift__c(
                Session__c = session.Id,
                Start_Time__c = Time.newInstance(13, 0, 0, 0),
                End_Time__c = Time.newInstance(15, 0, 0, 0)
            )
        };
        insert shifts;
    }

    @isTest
    static void testOverlapDetection_AssignUser() {
        List<Shift__c> shifts = [SELECT Id FROM Shift__c ORDER BY Start_Time__c];

        Test.startTest();
        shifts[0].User__c = UserInfo.getUserId();
        shifts[1].User__c = UserInfo.getUserId();
        update shifts;
        Test.stopTest();

        List<Shift__c> updatedShifts = [
            SELECT Has_Overlap__c FROM Shift__c
            WHERE User__c = :UserInfo.getUserId()
        ];

        System.assertEquals(2, updatedShifts.size(), 'Should have 2 assigned shifts');
        for (Shift__c shift : updatedShifts) {
            System.assertEquals(true, shift.Has_Overlap__c, 'Should have overlap');
        }
    }

    @isTest
    static void testNoOverlapDetection() {
        List<Shift__c> shifts = [SELECT Id FROM Shift__c ORDER BY Start_Time__c];

        Test.startTest();
        shifts[0].User__c = UserInfo.getUserId();
        shifts[2].User__c = UserInfo.getUserId();
        update shifts;
        Test.stopTest();

        List<Shift__c> updatedShifts = [
            SELECT Has_Overlap__c FROM Shift__c
            WHERE User__c = :UserInfo.getUserId()
        ];

        System.assertEquals(2, updatedShifts.size(), 'Should have 2 assigned shifts');
        for (Shift__c shift : updatedShifts) {
            System.assertEquals(false, shift.Has_Overlap__c, 'Should not have overlap');
        }
    }

    @isTest
    static void testOverlapDetection_DropUser() {
        List<Shift__c> shifts = [SELECT Id FROM Shift__c ORDER BY Start_Time__c];

        shifts[0].User__c = UserInfo.getUserId();
        shifts[1].User__c = UserInfo.getUserId();
        update shifts;

        Test.startTest();
        shifts[1].User__c = null;
        update new List<Shift__c>{ shifts[1] };
        Test.stopTest();

        Shift__c remainingShift = [
            SELECT Has_Overlap__c FROM Shift__c
            WHERE Id = :shifts[0].Id
        ];

        System.assertEquals(false, remainingShift.Has_Overlap__c, 'Overlap should be cleared');
    }

    @isTest
    static void testBulkOverlapDetection() {
        Session__c session = [SELECT Id FROM Session__c LIMIT 1];

        List<Shift__c> bulkShifts = new List<Shift__c>();
        for (Integer i = 0; i < 10; i++) {
            bulkShifts.add(new Shift__c(
                Session__c = session.Id,
                Start_Time__c = Time.newInstance(9, 0, 0, 0),
                End_Time__c = Time.newInstance(11, 0, 0, 0)
            ));
        }
        insert bulkShifts;

        Test.startTest();
        for (Shift__c shift : bulkShifts) {
            shift.User__c = UserInfo.getUserId();
        }
        update bulkShifts;
        Test.stopTest();

        List<Shift__c> updatedShifts = [
            SELECT Has_Overlap__c FROM Shift__c
            WHERE Id IN :bulkShifts
        ];

        for (Shift__c shift : updatedShifts) {
            System.assertEquals(true, shift.Has_Overlap__c, 'Should have overlap');
        }
    }
}
