@isTest
private class AdminRosterControllerTest {

    @testSetup
    static void setup() {
        Event__c event = new Event__c(Name = 'Test Event');
        insert event;

        Session_Type__c sessionType = new Session_Type__c(
            Name = 'Breakout',
            Event__c = event.Id
        );
        insert sessionType;

        Session__c session = new Session__c(
            Name = 'Test Session',
            Session_Type__c = sessionType.Id,
            Location__c = 'Room A',
            Min_Shifts__c = 2,
            Max_Shifts__c = 4
        );
        insert session;

        List<Shift__c> shifts = new List<Shift__c>{
            new Shift__c(
                Session__c = session.Id,
                Start_Time__c = Time.newInstance(9, 0, 0, 0),
                End_Time__c = Time.newInstance(11, 0, 0, 0),
                User__c = UserInfo.getUserId()
            ),
            new Shift__c(
                Session__c = session.Id,
                Start_Time__c = Time.newInstance(14, 0, 0, 0),
                End_Time__c = Time.newInstance(16, 0, 0, 0),
                User__c = UserInfo.getUserId()
            )
        };
        insert shifts;
    }

    @isTest
    static void testGetRosterData() {
        Test.startTest();
        AdminRosterController.RosterData data =
            AdminRosterController.getRosterData();
        Test.stopTest();

        System.assertNotEquals(null, data, 'Should return roster data');
        System.assertNotEquals(null, data.timeSlots, 'Should have time slots');
        System.assert(data.timeSlots.size() > 0, 'Should have at least one time slot');
        System.assert(data.rows.size() > 0, 'Should have at least one person row');
        System.assert(data.shifts.size() > 0, 'Should have shifts');
        System.assert(data.sessionTypes.contains('Breakout'), 'Should include Breakout type');
        System.assert(data.sessionNames.contains('Test Session'), 'Should include Test Session');
    }

    @isTest
    static void testGetRosterData_CellDetails() {
        Test.startTest();
        AdminRosterController.RosterData data =
            AdminRosterController.getRosterData();
        Test.stopTest();

        AdminRosterController.RosterRow row = data.rows[0];
        System.assertNotEquals(null, row.cellDetails, 'Should have cell details');
        System.assert(row.cellDetails.size() > 0, 'Should have at least one cell detail');

        // Check cell detail fields
        for (String slot : row.cellDetails.keySet()) {
            AdminRosterController.CellDetail detail = row.cellDetails.get(slot);
            System.assertNotEquals(null, detail.sessionName, 'Should have session name');
            System.assertNotEquals(null, detail.sessionType, 'Should have session type');
            System.assertNotEquals(null, detail.status, 'Should have status');
            System.assertNotEquals(null, detail.minReached, 'Should have minReached flag');
        }
    }

    @isTest
    static void testGetRosterData_ShiftWrapper() {
        Test.startTest();
        AdminRosterController.RosterData data =
            AdminRosterController.getRosterData();
        Test.stopTest();

        AdminRosterController.ShiftRosterWrapper shift = data.shifts[0];
        System.assertNotEquals(null, shift.id, 'Should have ID');
        System.assertNotEquals(null, shift.sessionName, 'Should have session name');
        System.assertNotEquals(null, shift.timeSlot, 'Should have time slot');
        System.assertNotEquals(null, shift.minReached, 'Should have minReached');
    }

    @isTest
    static void testGetRosterData_NoAssignments() {
        List<Shift__c> shifts = [SELECT Id FROM Shift__c];
        for (Shift__c shift : shifts) {
            shift.User__c = null;
        }
        update shifts;

        Test.startTest();
        AdminRosterController.RosterData data =
            AdminRosterController.getRosterData();
        Test.stopTest();

        System.assertEquals(0, data.rows.size(), 'Should have no person rows');
        System.assertEquals(2, data.shifts.size(), 'Should still have 2 shifts');
        System.assertEquals(false, data.shifts[0].isAssigned, 'Should not be assigned');
    }
}
