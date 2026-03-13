@IsTest
private class StaffingAgentActionsTest {

    @TestSetup
    static void setup() {
        Event__c event = new Event__c(Name = 'Test Event');
        insert event;

        Session_Type__c st = new Session_Type__c(Name = 'Booth', Event__c = event.Id);
        insert st;

        Session__c session = new Session__c(
            Name = 'Booth Session - Test',
            Session_Type__c = st.Id,
            Event__c = event.Id,
            Location__c = 'Hall A',
            Min_Shifts__c = 2,
            Max_Shifts__c = 5
        );
        insert session;

        List<Shift__c> shifts = new List<Shift__c>{
            new Shift__c(Session__c = session.Id,
                         Start_Time__c = Time.newInstance(8, 0, 0, 0),
                         End_Time__c = Time.newInstance(10, 0, 0, 0)),
            new Shift__c(Session__c = session.Id,
                         Start_Time__c = Time.newInstance(10, 0, 0, 0),
                         End_Time__c = Time.newInstance(12, 0, 0, 0)),
            new Shift__c(Session__c = session.Id,
                         Start_Time__c = Time.newInstance(9, 0, 0, 0),
                         End_Time__c = Time.newInstance(11, 0, 0, 0))
        };
        insert shifts;
    }

    @IsTest
    static void testGetAvailableSessions() {
        AgentAction_GetAvailableSessions.Request req = new AgentAction_GetAvailableSessions.Request();
        List<AgentAction_GetAvailableSessions.Result> results =
            AgentAction_GetAvailableSessions.execute(new List<AgentAction_GetAvailableSessions.Request>{ req });

        System.assertEquals(1, results[0].sessionCount);
        String summary = results[0].summary;
        System.assert(summary.contains('Booth Session'), 'Should contain session name');
        // Verify staffing format: 0/2 min — NEEDS STAFF (0 claimed, min=2)
        System.assert(summary.contains('staffing: 0/2 min'), 'Should show staffing ratio: ' + summary);
        System.assert(summary.contains('NEEDS STAFF'), 'Should flag NEEDS STAFF');
        // Verify shift times are shown
        System.assert(summary.contains('Available shifts:'), 'Should list available shifts');
        System.assert(summary.contains('08:00-10:00'), 'Should show shift times');
    }

    @IsTest
    static void testGetAvailableSessions_WithFilter() {
        AgentAction_GetAvailableSessions.Request req = new AgentAction_GetAvailableSessions.Request();
        req.sessionTypeFilter = 'Keynote';
        List<AgentAction_GetAvailableSessions.Result> results =
            AgentAction_GetAvailableSessions.execute(new List<AgentAction_GetAvailableSessions.Request>{ req });

        System.assertEquals(0, results[0].sessionCount);
    }

    @IsTest
    static void testGetAvailableSessions_StaffingReached() {
        // Assign all 3 shifts except one to meet min_shifts=2
        List<Shift__c> shifts = [SELECT Id FROM Shift__c ORDER BY Start_Time__c];
        shifts[0].User__c = UserInfo.getUserId();
        shifts[1].User__c = UserInfo.getUserId();
        update new List<Shift__c>{ shifts[0], shifts[1] };

        AgentAction_GetAvailableSessions.Request req = new AgentAction_GetAvailableSessions.Request();
        List<AgentAction_GetAvailableSessions.Result> results =
            AgentAction_GetAvailableSessions.execute(new List<AgentAction_GetAvailableSessions.Request>{ req });

        System.assertEquals(1, results[0].sessionCount);
        String summary = results[0].summary;
        System.assert(summary.contains('staffing: 2/2 min reached'), 'Should show min reached: ' + summary);
    }

    @IsTest
    static void testGetAvailableSessions_OverlapWarning() {
        // Assign shift 08:00-10:00 to current user
        Shift__c myShift = [SELECT Id FROM Shift__c WHERE Start_Time__c = :Time.newInstance(8, 0, 0, 0) LIMIT 1];
        myShift.User__c = UserInfo.getUserId();
        update myShift;

        AgentAction_GetAvailableSessions.Request req = new AgentAction_GetAvailableSessions.Request();
        List<AgentAction_GetAvailableSessions.Result> results =
            AgentAction_GetAvailableSessions.execute(new List<AgentAction_GetAvailableSessions.Request>{ req });

        String summary = results[0].summary;
        // The 09:00-11:00 shift overlaps with user's 08:00-10:00
        System.assert(summary.contains('[OVERLAP'), 'Should show overlap warning: ' + summary);
    }

    @IsTest
    static void testClaimShift() {
        AgentAction_ClaimShift.Request req = new AgentAction_ClaimShift.Request();
        req.sessionName = 'Booth Session';
        List<AgentAction_ClaimShift.Result> results =
            AgentAction_ClaimShift.execute(new List<AgentAction_ClaimShift.Request>{ req });

        System.assert(results[0].success);
        System.assert(results[0].message.contains('Successfully claimed'));
    }

    @IsTest
    static void testClaimShift_NoMatch() {
        AgentAction_ClaimShift.Request req = new AgentAction_ClaimShift.Request();
        req.sessionName = 'Nonexistent';
        List<AgentAction_ClaimShift.Result> results =
            AgentAction_ClaimShift.execute(new List<AgentAction_ClaimShift.Request>{ req });

        System.assert(!results[0].success);
        System.assert(results[0].message.contains('No session found'));
    }

    @IsTest
    static void testGetMyShifts_Empty() {
        AgentAction_GetMyShifts.Request req = new AgentAction_GetMyShifts.Request();
        List<AgentAction_GetMyShifts.Result> results =
            AgentAction_GetMyShifts.execute(new List<AgentAction_GetMyShifts.Request>{ req });

        System.assertEquals(0, results[0].shiftCount);
        System.assert(results[0].summary.contains('no shifts'));
    }

    @IsTest
    static void testGetMyShifts_WithShifts() {
        List<Shift__c> shifts = [SELECT Id FROM Shift__c ORDER BY Start_Time__c LIMIT 2];
        for (Shift__c sh : shifts) {
            sh.User__c = UserInfo.getUserId();
        }
        update shifts;

        AgentAction_GetMyShifts.Request req = new AgentAction_GetMyShifts.Request();
        List<AgentAction_GetMyShifts.Result> results =
            AgentAction_GetMyShifts.execute(new List<AgentAction_GetMyShifts.Request>{ req });

        System.assertEquals(2, results[0].shiftCount);
    }

    @IsTest
    static void testDropShift() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];
        shift.User__c = UserInfo.getUserId();
        update shift;

        AgentAction_DropShift.Request req = new AgentAction_DropShift.Request();
        req.sessionName = 'Booth Session';
        List<AgentAction_DropShift.Result> results =
            AgentAction_DropShift.execute(new List<AgentAction_DropShift.Request>{ req });

        System.assert(results[0].success);
        System.assert(results[0].message.contains('Successfully dropped'));
    }

    @IsTest
    static void testDropShift_NoMatch() {
        AgentAction_DropShift.Request req = new AgentAction_DropShift.Request();
        req.sessionName = 'Nonexistent';
        List<AgentAction_DropShift.Result> results =
            AgentAction_DropShift.execute(new List<AgentAction_DropShift.Request>{ req });

        System.assert(!results[0].success);
    }

    @IsTest
    static void testCheckOverlaps_None() {
        AgentAction_CheckOverlaps.Request req = new AgentAction_CheckOverlaps.Request();
        List<AgentAction_CheckOverlaps.Result> results =
            AgentAction_CheckOverlaps.execute(new List<AgentAction_CheckOverlaps.Request>{ req });

        System.assert(!results[0].hasOverlaps);
        System.assertEquals(0, results[0].overlapCount);
    }

    @IsTest
    static void testCheckOverlaps_WithOverlaps() {
        // Assign overlapping shifts (08-10 and 09-11) to current user
        Shift__c shift1 = [SELECT Id FROM Shift__c WHERE Start_Time__c = :Time.newInstance(8, 0, 0, 0) LIMIT 1];
        Shift__c shift2 = [SELECT Id FROM Shift__c WHERE Start_Time__c = :Time.newInstance(9, 0, 0, 0) LIMIT 1];

        shift1.User__c = UserInfo.getUserId();
        shift2.User__c = UserInfo.getUserId();

        Test.startTest();
        update new List<Shift__c>{ shift1, shift2 };
        Test.stopTest();

        // Verify trigger flagged overlaps
        Integer flagged = [SELECT COUNT() FROM Shift__c WHERE Has_Overlap__c = true AND User__c = :UserInfo.getUserId()];

        // The action should reflect what's in the DB
        AgentAction_CheckOverlaps.Request req = new AgentAction_CheckOverlaps.Request();
        List<AgentAction_CheckOverlaps.Result> results =
            AgentAction_CheckOverlaps.execute(new List<AgentAction_CheckOverlaps.Request>{ req });

        System.assertEquals(flagged > 0, results[0].hasOverlaps);
        System.assertEquals(flagged, results[0].overlapCount);
    }

    @IsTest
    static void testFormatTime() {
        System.assertEquals('08:00', StaffingAgentActions.formatTime(Time.newInstance(8, 0, 0, 0)));
        System.assertEquals('14:30', StaffingAgentActions.formatTime(Time.newInstance(14, 30, 0, 0)));
        System.assertEquals('--:--', StaffingAgentActions.formatTime(null));
    }
}
