@IsTest
private class FreezeControlControllerTest {

    @TestSetup
    static void setup() {
        TestDataFactory.generateFullDataset();

        User adminUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(adminUser) {
            User empUser = [SELECT Id FROM User WHERE LastName LIKE 'Employee%' AND IsActive = true LIMIT 1];
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Staffing_App_Employee' LIMIT 1];
            insert new PermissionSetAssignment(AssigneeId = empUser.Id, PermissionSetId = ps.Id);
        }
    }

    @IsTest
    static void testGetSessionTypesWithSessions() {
        List<FreezeControlController.SessionTypeWrapper> result =
            FreezeControlController.getSessionTypesWithSessions();
        System.assert(!result.isEmpty(), 'Should return session types');
        System.assert(!result[0].sessions.isEmpty(), 'Should include child sessions');
    }

    @IsTest
    static void testToggleSessionTypeFreeze() {
        Session_Type__c st = [SELECT Id, Is_Frozen__c FROM Session_Type__c LIMIT 1];
        System.assertEquals(false, st.Is_Frozen__c);

        FreezeControlController.toggleSessionTypeFreeze(st.Id, true);

        st = [SELECT Is_Frozen__c FROM Session_Type__c WHERE Id = :st.Id];
        System.assertEquals(true, st.Is_Frozen__c);

        FreezeControlController.toggleSessionTypeFreeze(st.Id, false);

        st = [SELECT Is_Frozen__c FROM Session_Type__c WHERE Id = :st.Id];
        System.assertEquals(false, st.Is_Frozen__c);
    }

    @IsTest
    static void testToggleSessionFreeze() {
        Session__c s = [SELECT Id, Is_Frozen__c FROM Session__c LIMIT 1];
        System.assertEquals(false, s.Is_Frozen__c);

        FreezeControlController.toggleSessionFreeze(s.Id, true);

        s = [SELECT Is_Frozen__c FROM Session__c WHERE Id = :s.Id];
        System.assertEquals(true, s.Is_Frozen__c);
    }

    @IsTest
    static void testBulkFreezeSessionsForType() {
        Session_Type__c st = [SELECT Id FROM Session_Type__c LIMIT 1];

        FreezeControlController.bulkFreezeSessionsForType(st.Id, true);

        List<Session__c> sessions = [
            SELECT Is_Frozen__c FROM Session__c WHERE Session_Type__c = :st.Id
        ];
        for (Session__c s : sessions) {
            System.assertEquals(true, s.Is_Frozen__c);
        }

        FreezeControlController.bulkFreezeSessionsForType(st.Id, false);

        sessions = [SELECT Is_Frozen__c FROM Session__c WHERE Session_Type__c = :st.Id];
        for (Session__c s : sessions) {
            System.assertEquals(false, s.Is_Frozen__c);
        }
    }

    @IsTest
    static void testClaimShiftBlockedWhenFrozen() {
        User empUser = [SELECT Id FROM User WHERE LastName LIKE 'Employee%' AND IsActive = true LIMIT 1];
        Shift__c shift = [SELECT Id, Session__c FROM Shift__c WHERE User__c = null LIMIT 1];

        Session__c session = new Session__c(Id = shift.Session__c, Is_Frozen__c = true);
        update session;

        Test.startTest();
        System.runAs(empUser) {
            try {
                ShiftMarketplaceController.claimShift(shift.Id);
                System.assert(false, 'Should have thrown');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('frozen'), 'Error should mention frozen: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testDropShiftBlockedWhenFrozen() {
        User empUser = [SELECT Id FROM User WHERE LastName LIKE 'Employee%' AND IsActive = true LIMIT 1];
        Shift__c shift = [SELECT Id, Session__c FROM Shift__c WHERE User__c = null LIMIT 1];

        shift.User__c = empUser.Id;
        update shift;

        Session__c session = new Session__c(Id = shift.Session__c, Is_Frozen__c = true);
        update session;

        Test.startTest();
        System.runAs(empUser) {
            try {
                ShiftMarketplaceController.dropShift(shift.Id);
                System.assert(false, 'Should have thrown');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('frozen'), 'Error should mention frozen: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testQuickAssignBlockedWhenFrozen() {
        User empUser = [SELECT Id FROM User WHERE LastName LIKE 'Employee%' AND IsActive = true LIMIT 1];
        Session__c session = [SELECT Id FROM Session__c LIMIT 1];
        session.Is_Frozen__c = true;
        update session;

        Test.startTest();
        System.runAs(empUser) {
            try {
                ShiftMarketplaceController.quickAssign(session.Id);
                System.assert(false, 'Should have thrown');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('frozen'), 'Error should mention frozen: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetSessionsExcludesFrozenForEmployee() {
        User empUser = [SELECT Id FROM User WHERE LastName LIKE 'Employee%' AND IsActive = true LIMIT 1];
        Session__c session = [SELECT Id FROM Session__c LIMIT 1];
        session.Is_Frozen__c = true;
        update session;

        Test.startTest();
        List<ShiftMarketplaceController.SessionWrapper> results;
        System.runAs(empUser) {
            results = ShiftMarketplaceController.getSessionsNeedingStaff();
        }
        Test.stopTest();

        for (ShiftMarketplaceController.SessionWrapper w : results) {
            System.assertNotEquals(session.Id, w.id, 'Frozen session should be excluded');
        }
    }

    @IsTest
    static void testInheritedFreezeFromSessionType() {
        User empUser = [SELECT Id FROM User WHERE LastName LIKE 'Employee%' AND IsActive = true LIMIT 1];
        Session_Type__c st = [SELECT Id FROM Session_Type__c LIMIT 1];
        st.Is_Frozen__c = true;
        update st;

        Session__c session = [SELECT Id FROM Session__c WHERE Session_Type__c = :st.Id LIMIT 1];
        Shift__c shift = getUnclaimedShiftForSession(session.Id);

        Test.startTest();
        System.runAs(empUser) {
            try {
                ShiftMarketplaceController.claimShift(shift.Id);
                System.assert(false, 'Should have thrown');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('frozen'), 'Error should mention frozen: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testIsSessionFrozenMethod() {
        Session__c session = [SELECT Id FROM Session__c LIMIT 1];
        System.assertEquals(false, ShiftMarketplaceController.isSessionFrozen(session.Id));

        session.Is_Frozen__c = true;
        update session;
        System.assertEquals(true, ShiftMarketplaceController.isSessionFrozen(session.Id));
    }

    @IsTest
    static void testOverlapDashboardDropBlockedWhenFrozen() {
        User empUser = [SELECT Id FROM User WHERE LastName LIKE 'Employee%' AND IsActive = true LIMIT 1];
        Shift__c shift = [SELECT Id, Session__c FROM Shift__c WHERE User__c = null LIMIT 1];

        shift.User__c = empUser.Id;
        update shift;

        Session__c session = new Session__c(Id = shift.Session__c, Is_Frozen__c = true);
        update session;

        Test.startTest();
        System.runAs(empUser) {
            try {
                OverlapDashboardController.dropShift(shift.Id);
                System.assert(false, 'Should have thrown');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('frozen'), 'Error should mention frozen: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testAdminCanClaimOnFrozenSession() {
        Shift__c shift = [SELECT Id, Session__c FROM Shift__c WHERE User__c = null LIMIT 1];

        Session__c session = new Session__c(Id = shift.Session__c, Is_Frozen__c = true);
        update session;

        Test.startTest();
        String claimedId = ShiftMarketplaceController.claimShift(shift.Id);
        Test.stopTest();

        System.assertNotEquals(null, claimedId, 'Admin should be able to claim frozen shift');
    }

    private static Shift__c getUnclaimedShiftForSession(Id sessionId) {
        List<Shift__c> shifts = [SELECT Id FROM Shift__c WHERE Session__c = :sessionId AND User__c = null LIMIT 1];
        if (!shifts.isEmpty()) {
            return shifts[0];
        }
        Shift__c shift = [SELECT Id FROM Shift__c WHERE Session__c = :sessionId LIMIT 1];
        shift.User__c = null;
        update shift;
        return shift;
    }
}
