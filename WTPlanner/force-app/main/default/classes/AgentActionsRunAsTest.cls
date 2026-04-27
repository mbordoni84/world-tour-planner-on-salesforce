@IsTest
private class AgentActionsRunAsTest {

    @IsTest
    static void testAllActionsAsAgentUser() {
        // Create test data
        Event__c event = new Event__c(Name = 'World Tour Milan 2026');
        insert event;

        Session_Type__c st = new Session_Type__c(Name = 'Breakout', Event__c = event.Id, Description__c = 'Breakout sessions');
        insert st;

        Session__c session = new Session__c(
            Name = 'Breakout Session - World Tour',
            Session_Type__c = st.Id,
            Event__c = event.Id,
            Location__c = 'Breakout Room B',
            Min_Shifts__c = 2,
            Max_Shifts__c = 5
        );
        insert session;

        List<Shift__c> shifts = new List<Shift__c>{
            new Shift__c(Session__c = session.Id, Start_Time__c = Time.newInstance(8,0,0,0), End_Time__c = Time.newInstance(10,0,0,0)),
            new Shift__c(Session__c = session.Id, Start_Time__c = Time.newInstance(10,0,0,0), End_Time__c = Time.newInstance(12,0,0,0)),
            new Shift__c(Session__c = session.Id, Start_Time__c = Time.newInstance(14,0,0,0), End_Time__c = Time.newInstance(16,0,0,0))
        };
        insert shifts;

        // Find the agent user
        List<User> agentUsers = [SELECT Id, Name FROM User WHERE Username = 'event_staffing_agent@00dj9000002fddn2053032340.ext' LIMIT 1];

        // If agent user doesn't exist in test context, create a stand-in
        User testUser;
        if (agentUsers.isEmpty()) {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            testUser = new User(
                FirstName = 'Agent', LastName = 'Test User',
                Email = 'agenttest@worldtour.test',
                Username = 'agenttest@worldtour.test.' + System.currentTimeMillis(),
                Alias = 'agtest', TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US', ProfileId = p.Id
            );
            insert testUser;
        } else {
            testUser = agentUsers[0];
        }

        System.runAs(testUser) {
            Test.startTest();

            // 1. Get Available Sessions
            AgentAction_GetAvailableSessions.Request req1 = new AgentAction_GetAvailableSessions.Request();
            List<AgentAction_GetAvailableSessions.Result> res1 = AgentAction_GetAvailableSessions.execute(
                new List<AgentAction_GetAvailableSessions.Request>{ req1 });
            System.assert(res1[0].sessionCount > 0, 'Should find available sessions');
            System.debug('GET AVAILABLE: ' + res1[0].summary);

            // 2. Get My Shifts (empty)
            AgentAction_GetMyShifts.Request req2 = new AgentAction_GetMyShifts.Request();
            List<AgentAction_GetMyShifts.Result> res2 = AgentAction_GetMyShifts.execute(
                new List<AgentAction_GetMyShifts.Request>{ req2 });
            System.assertEquals(0, res2[0].shiftCount, 'Should have no shifts initially');
            System.debug('MY SHIFTS (before): ' + res2[0].summary);

            // 3. Claim Shift
            AgentAction_ClaimShift.Request req3 = new AgentAction_ClaimShift.Request();
            req3.sessionName = 'Breakout';
            List<AgentAction_ClaimShift.Result> res3 = AgentAction_ClaimShift.execute(
                new List<AgentAction_ClaimShift.Request>{ req3 });
            System.assert(res3[0].success, 'Claim should succeed: ' + res3[0].message);
            System.debug('CLAIM: ' + res3[0].message);

            // 4. Get My Shifts (should have 1)
            List<AgentAction_GetMyShifts.Result> res4 = AgentAction_GetMyShifts.execute(
                new List<AgentAction_GetMyShifts.Request>{ req2 });
            System.assertEquals(1, res4[0].shiftCount, 'Should have 1 shift after claim');
            System.debug('MY SHIFTS (after claim): ' + res4[0].summary);

            // 5. Check Overlaps (should be none with 1 shift)
            AgentAction_CheckOverlaps.Request req5 = new AgentAction_CheckOverlaps.Request();
            List<AgentAction_CheckOverlaps.Result> res5 = AgentAction_CheckOverlaps.execute(
                new List<AgentAction_CheckOverlaps.Request>{ req5 });
            System.assert(!res5[0].hasOverlaps, 'Should have no overlaps with 1 shift');
            System.debug('OVERLAPS: ' + res5[0].summary);

            // 6. Drop Shift
            AgentAction_DropShift.Request req6 = new AgentAction_DropShift.Request();
            req6.sessionName = 'Breakout';
            List<AgentAction_DropShift.Result> res6 = AgentAction_DropShift.execute(
                new List<AgentAction_DropShift.Request>{ req6 });
            System.assert(res6[0].success, 'Drop should succeed: ' + res6[0].message);
            System.debug('DROP: ' + res6[0].message);

            // 7. Confirm empty
            List<AgentAction_GetMyShifts.Result> res7 = AgentAction_GetMyShifts.execute(
                new List<AgentAction_GetMyShifts.Request>{ req2 });
            System.assertEquals(0, res7[0].shiftCount, 'Should have 0 shifts after drop');
            System.debug('MY SHIFTS (after drop): ' + res7[0].summary);

            Test.stopTest();

            System.debug('=== ALL AGENT ACTIONS PASSED ===');
        }
    }
}
