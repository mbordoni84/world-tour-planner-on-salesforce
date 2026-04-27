@isTest
private class ShiftMarketplaceControllerTest {

    @testSetup
    static void setup() {
        Event__c event = new Event__c(Name = 'Test Event');
        insert event;

        Session_Type__c sessionType = new Session_Type__c(
            Name = 'Theatre',
            Event__c = event.Id
        );
        insert sessionType;

        Session__c session = new Session__c(
            Name = 'Test Session',
            Session_Type__c = sessionType.Id,
            Location__c = 'Main Theatre',
            Description__c = 'Test Description',
            Min_Shifts__c = 2,
            Max_Shifts__c = 5
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
                Start_Time__c = Time.newInstance(14, 0, 0, 0),
                End_Time__c = Time.newInstance(16, 0, 0, 0)
            )
        };
        insert shifts;
    }

    @isTest
    static void testGetSessionsNeedingStaff() {
        Test.startTest();
        List<ShiftMarketplaceController.SessionWrapper> sessions =
            ShiftMarketplaceController.getSessionsNeedingStaff();
        Test.stopTest();

        System.assertNotEquals(null, sessions, 'Should return sessions');
        System.assertEquals(1, sessions.size(), 'Should have 1 session');
        System.assertEquals('Test Session', sessions[0].name, 'Should have session name');
        System.assertEquals(true, sessions[0].needsStaff, 'Should need staff');
        System.assertEquals(2, sessions[0].totalShifts, 'Should have 2 shifts');
        System.assertEquals(0, sessions[0].claimedShifts, 'Should have 0 claimed');
    }

    @isTest
    static void testGetMyShifts() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];
        shift.User__c = UserInfo.getUserId();
        update shift;

        Test.startTest();
        List<ShiftMarketplaceController.ShiftWrapper> myShifts =
            ShiftMarketplaceController.getMyShifts();
        Test.stopTest();

        System.assertNotEquals(null, myShifts, 'Should return shifts');
        System.assertEquals(1, myShifts.size(), 'Should have 1 shift');
    }

    @isTest
    static void testClaimShift() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];

        Test.startTest();
        String shiftId = ShiftMarketplaceController.claimShift(shift.Id);
        Test.stopTest();

        System.assertNotEquals(null, shiftId, 'Should return shift ID');

        Shift__c updatedShift = [
            SELECT User__c FROM Shift__c WHERE Id = :shiftId
        ];
        System.assertEquals(UserInfo.getUserId(), updatedShift.User__c, 'Should be assigned to current user');
    }

    @isTest
    static void testClaimShift_AlreadyClaimed() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];
        shift.User__c = UserInfo.getUserId();
        update shift;

        Test.startTest();
        try {
            ShiftMarketplaceController.claimShift(shift.Id);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('already claimed'), 'Should indicate already claimed');
        }
        Test.stopTest();
    }

    @isTest
    static void testQuickAssign() {
        Session__c session = [SELECT Id FROM Session__c LIMIT 1];

        Test.startTest();
        String shiftId = ShiftMarketplaceController.quickAssign(session.Id);
        Test.stopTest();

        System.assertNotEquals(null, shiftId, 'Should return shift ID');

        Shift__c updatedShift = [
            SELECT User__c FROM Shift__c WHERE Id = :shiftId
        ];
        System.assertEquals(UserInfo.getUserId(), updatedShift.User__c, 'Should be assigned to current user');
    }

    @isTest
    static void testQuickAssign_CreatesNewShift() {
        Session__c session = [SELECT Id FROM Session__c LIMIT 1];

        // Claim all existing shifts
        List<Shift__c> shifts = [SELECT Id FROM Shift__c WHERE Session__c = :session.Id];
        for (Shift__c shift : shifts) {
            shift.User__c = UserInfo.getUserId();
        }
        update shifts;

        Test.startTest();
        String newShiftId = ShiftMarketplaceController.quickAssign(session.Id);
        Test.stopTest();

        System.assertNotEquals(null, newShiftId, 'Should return new shift ID');

        Integer totalShifts = [SELECT COUNT() FROM Shift__c WHERE Session__c = :session.Id];
        System.assertEquals(3, totalShifts, 'Should have created a new shift');
    }

    @isTest
    static void testDropShift() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];
        shift.User__c = UserInfo.getUserId();
        update shift;

        Test.startTest();
        ShiftMarketplaceController.dropShift(shift.Id);
        Test.stopTest();

        Shift__c updatedShift = [
            SELECT User__c FROM Shift__c WHERE Id = :shift.Id
        ];
        System.assertEquals(null, updatedShift.User__c, 'User should be cleared');
    }

    @isTest
    static void testCheckOverlap_NoOverlap() {
        List<Shift__c> shifts = [SELECT Id FROM Shift__c ORDER BY Start_Time__c];

        shifts[0].User__c = UserInfo.getUserId();
        update shifts[0];

        Test.startTest();
        ShiftMarketplaceController.OverlapCheckResult result =
            ShiftMarketplaceController.checkOverlap(shifts[1].Id);
        Test.stopTest();

        System.assertEquals(false, result.hasOverlap, 'Should not have overlap');
    }

    @isTest
    static void testCheckOverlap_HasOverlap() {
        Session__c session = [SELECT Id FROM Session__c LIMIT 1];

        Shift__c overlappingShift = new Shift__c(
            Session__c = session.Id,
            Start_Time__c = Time.newInstance(10, 0, 0, 0),
            End_Time__c = Time.newInstance(12, 0, 0, 0)
        );
        insert overlappingShift;

        Shift__c firstShift = [SELECT Id FROM Shift__c WHERE Start_Time__c = :Time.newInstance(9, 0, 0, 0) LIMIT 1];
        firstShift.User__c = UserInfo.getUserId();
        update firstShift;

        Test.startTest();
        ShiftMarketplaceController.OverlapCheckResult result =
            ShiftMarketplaceController.checkOverlap(overlappingShift.Id);
        Test.stopTest();

        System.assertEquals(true, result.hasOverlap, 'Should have overlap');
        System.assertNotEquals(null, result.message, 'Should have overlap message');
    }

    @isTest
    static void testIsCurrentUserAdmin() {
        Test.startTest();
        Boolean result = ShiftMarketplaceController.isCurrentUserAdmin();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a boolean');
    }

    @isTest
    static void testGetEligibleUsers() {
        Test.startTest();
        List<ShiftMarketplaceController.UserOption> users =
            ShiftMarketplaceController.getEligibleUsers();
        Test.stopTest();

        System.assertNotEquals(null, users, 'Should return list');
    }

    @isTest
    static void testAdminAssignShift() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];
        Id currentUserId = UserInfo.getUserId();

        Test.startTest();
        ShiftMarketplaceController.adminAssignShift(shift.Id, currentUserId);
        Test.stopTest();

        Shift__c updated = [SELECT User__c FROM Shift__c WHERE Id = :shift.Id];
        System.assertEquals(currentUserId, updated.User__c, 'Shift should be assigned');
    }

    @isTest
    static void testAdminAssignShift_Reassign() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];
        shift.User__c = UserInfo.getUserId();
        update shift;

        Id newUserId = UserInfo.getUserId();

        Test.startTest();
        ShiftMarketplaceController.adminAssignShift(shift.Id, newUserId);
        Test.stopTest();

        Shift__c updated = [SELECT User__c FROM Shift__c WHERE Id = :shift.Id];
        System.assertEquals(newUserId, updated.User__c, 'Shift should be reassigned');
    }

    @isTest
    static void testAdminUnassignShift() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];
        shift.User__c = UserInfo.getUserId();
        update shift;

        Test.startTest();
        ShiftMarketplaceController.adminUnassignShift(shift.Id);
        Test.stopTest();

        Shift__c updated = [SELECT User__c FROM Shift__c WHERE Id = :shift.Id];
        System.assertEquals(null, updated.User__c, 'User should be cleared');
    }

    @isTest
    static void testCheckOverlapsForUsers() {
        Session__c session = [SELECT Id FROM Session__c LIMIT 1];
        List<Shift__c> shifts = [SELECT Id FROM Shift__c WHERE Session__c = :session.Id];

        shifts[0].User__c = UserInfo.getUserId();
        update shifts[0];

        Test.startTest();
        Map<String, List<String>> result =
            ShiftMarketplaceController.checkOverlapsForUsers(
                new List<String>{ shifts[1].Id }
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return map');
        System.assert(result.containsKey(String.valueOf(shifts[1].Id)), 'Should contain shift key');
    }

    @isTest
    static void testShiftDetailHasAssignedUserId() {
        Shift__c shift = [SELECT Id FROM Shift__c LIMIT 1];
        shift.User__c = UserInfo.getUserId();
        update shift;

        Test.startTest();
        List<ShiftMarketplaceController.SessionWrapper> sessions =
            ShiftMarketplaceController.getSessionsNeedingStaff();
        Test.stopTest();

        Boolean foundUserId = false;
        for (ShiftMarketplaceController.ShiftDetail sd : sessions[0].shifts) {
            if (sd.assignedUserId != null) {
                foundUserId = true;
                break;
            }
        }
        System.assert(foundUserId, 'ShiftDetail should include assignedUserId');
    }
}
