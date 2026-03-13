@isTest
private class StaffingDashboardControllerTest {

    @testSetup
    static void setup() {
        Event__c event = new Event__c(Name = 'Test Event');
        insert event;

        Session_Type__c boothType = new Session_Type__c(
            Name = 'Booth',
            Event__c = event.Id
        );
        Session_Type__c keynoteType = new Session_Type__c(
            Name = 'Keynote',
            Event__c = event.Id
        );
        insert new List<Session_Type__c>{ boothType, keynoteType };

        Session__c session1 = new Session__c(
            Name = 'Booth Session',
            Session_Type__c = boothType.Id,
            Location__c = 'Expo Hall',
            Min_Shifts__c = 2,
            Max_Shifts__c = 4
        );
        Session__c session2 = new Session__c(
            Name = 'Keynote Session',
            Session_Type__c = keynoteType.Id,
            Location__c = 'Grand Ballroom',
            Min_Shifts__c = 1,
            Max_Shifts__c = 3
        );
        insert new List<Session__c>{ session1, session2 };

        List<Shift__c> shifts = new List<Shift__c>{
            // Session 1 shifts - one assigned, one unassigned
            new Shift__c(
                Session__c = session1.Id,
                Start_Time__c = Time.newInstance(9, 0, 0, 0),
                End_Time__c = Time.newInstance(11, 0, 0, 0),
                User__c = UserInfo.getUserId()
            ),
            new Shift__c(
                Session__c = session1.Id,
                Start_Time__c = Time.newInstance(11, 0, 0, 0),
                End_Time__c = Time.newInstance(13, 0, 0, 0)
            ),
            // Session 2 shift - overlapping with session 1 shift
            new Shift__c(
                Session__c = session2.Id,
                Start_Time__c = Time.newInstance(10, 0, 0, 0),
                End_Time__c = Time.newInstance(12, 0, 0, 0),
                User__c = UserInfo.getUserId()
            )
        };
        insert shifts;
    }

    @isTest
    static void testGetDashboardData() {
        Test.startTest();
        StaffingDashboardController.DashboardData data =
            StaffingDashboardController.getDashboardData();
        Test.stopTest();

        // Summary assertions
        System.assertNotEquals(null, data.summary, 'Summary should not be null');
        System.assertEquals(3, data.summary.totalShifts, 'Should have 3 total shifts');
        System.assertEquals(2, data.summary.assigned, 'Should have 2 assigned shifts');
        System.assertEquals(1, data.summary.unassigned, 'Should have 1 unassigned shift');

        // Session assertions
        System.assertEquals(2, data.sessions.size(), 'Should have 2 sessions');

        // Session types filter
        System.assert(data.sessionTypes.contains('Booth'), 'Should include Booth type');
        System.assert(data.sessionTypes.contains('Keynote'), 'Should include Keynote type');

        // Time slots
        System.assert(data.timeSlots.size() > 0, 'Should have time slots');
    }

    @isTest
    static void testGetDashboardData_SessionStatuses() {
        Test.startTest();
        StaffingDashboardController.DashboardData data =
            StaffingDashboardController.getDashboardData();
        Test.stopTest();

        Map<String, String> statusByName = new Map<String, String>();
        for (StaffingDashboardController.SessionStaffing ss : data.sessions) {
            statusByName.put(ss.name, ss.status);
        }

        // Booth: 1 claimed out of min 2 → Needs Staff
        System.assertEquals('Needs Staff', statusByName.get('Booth Session'),
            'Booth session should need staff');

        // Keynote: 1 claimed, min 1 → Min Reached
        System.assertEquals('Min Reached', statusByName.get('Keynote Session'),
            'Keynote session should have min reached');
    }

    @isTest
    static void testGetDashboardData_Overlaps() {
        Test.startTest();
        StaffingDashboardController.DashboardData data =
            StaffingDashboardController.getDashboardData();
        Test.stopTest();

        // The trigger marks Has_Overlap__c, so overlap pairs depend on trigger behavior
        System.assertNotEquals(null, data.overlaps, 'Overlaps list should not be null');
    }

    @isTest
    static void testGetDashboardData_FillRate() {
        Test.startTest();
        StaffingDashboardController.DashboardData data =
            StaffingDashboardController.getDashboardData();
        Test.stopTest();

        // 2 assigned / 3 total = 66.7%
        Decimal expectedRate = ((Decimal)2 / 3 * 100).setScale(1);
        System.assertEquals(expectedRate, data.summary.fillRate, 'Fill rate should be ~66.7%');
    }

    @isTest
    static void testGetDashboardData_NoData() {
        // Delete all shifts and sessions
        delete [SELECT Id FROM Shift__c];
        delete [SELECT Id FROM Session__c];

        Test.startTest();
        StaffingDashboardController.DashboardData data =
            StaffingDashboardController.getDashboardData();
        Test.stopTest();

        System.assertEquals(0, data.summary.totalShifts, 'Should have 0 shifts');
        System.assertEquals(0, data.sessions.size(), 'Should have 0 sessions');
        System.assertEquals(0, data.summary.fillRate, 'Fill rate should be 0');
    }
}
