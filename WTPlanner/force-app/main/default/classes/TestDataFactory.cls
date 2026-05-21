public class TestDataFactory {

    public static void generateFullDataset() {
        List<User> testUsers = createTestUsers(15);
        Event__c event = createEvent();
        List<Session_Type__c> sessionTypes = createSessionTypes(event.Id);
        List<Session__c> sessions = createSessions(sessionTypes);
        List<Shift__c> shifts = createShifts(sessions);
        assignShiftsWithOverlaps(shifts, testUsers);

        System.debug('Test data created successfully!');
        System.debug('Users: ' + testUsers.size());
        System.debug('Session Types: ' + sessionTypes.size());
        System.debug('Sessions: ' + sessions.size());
        System.debug('Shifts: ' + shifts.size());
    }

    @TestVisible
    private static Event__c createEvent() {
        List<Event__c> existing = [SELECT Id FROM Event__c WHERE Name = 'World Tour Milan 2026' LIMIT 1];
        if (!existing.isEmpty()) {
            return existing[0];
        }
        Event__c event = new Event__c(
            Name = 'World Tour Milan 2026'
        );
        insert event;
        return event;
    }

    @TestVisible
    private static List<User> createTestUsers(Integer count) {
        List<User> users = new List<User>();

        Profile standardProfile = [
            SELECT Id FROM Profile
            WHERE Name = 'Standard User' LIMIT 1
        ];

        for (Integer i = 1; i <= count; i++) {
            User u = new User(
                FirstName = 'Test',
                LastName = 'Employee ' + i,
                Email = 'testemp' + i + '@worldtour.test',
                Username = 'testemp' + i + '@worldtour.test.' + System.currentTimeMillis(),
                Alias = 'temp' + i,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = standardProfile.Id
            );
            users.add(u);
        }

        insert users;
        return users;
    }

    @TestVisible
    private static List<Session_Type__c> createSessionTypes(Id eventId) {
        List<String> typeNames = new List<String>{
            'Booth', 'Theatre', 'Keynote', 'Consultation', 'SIC', 'Breakout'
        };

        Map<String, Session_Type__c> existingByName = new Map<String, Session_Type__c>();
        for (Session_Type__c st : [SELECT Id, Name FROM Session_Type__c WHERE Name IN :typeNames]) {
            existingByName.put(st.Name, st);
        }

        List<Session_Type__c> toInsert = new List<Session_Type__c>();
        for (String typeName : typeNames) {
            if (!existingByName.containsKey(typeName)) {
                toInsert.add(new Session_Type__c(
                    Name = typeName,
                    Event__c = eventId,
                    Description__c = typeName + ' type sessions'
                ));
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
            for (Session_Type__c st : toInsert) {
                existingByName.put(st.Name, st);
            }
        }

        List<Session_Type__c> sessionTypes = new List<Session_Type__c>();
        for (String typeName : typeNames) {
            sessionTypes.add(existingByName.get(typeName));
        }
        return sessionTypes;
    }

    @TestVisible
    private static List<Session__c> createSessions(List<Session_Type__c> sessionTypes) {
        List<Session__c> sessions = new List<Session__c>();

        for (Session_Type__c sessionType : sessionTypes) {
            sessions.add(new Session__c(
                Name = sessionType.Name + ' Session - World Tour',
                Session_Type__c = sessionType.Id,
                Description__c = 'Exciting ' + sessionType.Name.toLowerCase() + ' session for attendees',
                Location__c = getLocationForType(sessionType.Name),
                Min_Shifts__c = 2,
                Max_Shifts__c = 5
            ));
        }

        insert sessions;
        return sessions;
    }

    @TestVisible
    private static List<Shift__c> createShifts(List<Session__c> sessions) {
        List<Shift__c> shifts = new List<Shift__c>();

        List<TimeSlot> timeSlots = new List<TimeSlot>{
            new TimeSlot(8, 0, 10, 0),
            new TimeSlot(10, 0, 12, 0),
            new TimeSlot(12, 0, 14, 0),
            new TimeSlot(14, 0, 16, 0),
            new TimeSlot(16, 0, 18, 0),
            new TimeSlot(18, 0, 20, 0)
        };

        for (Session__c session : sessions) {
            for (Integer i = 0; i < 5 && i < timeSlots.size(); i++) {
                TimeSlot slot = timeSlots[i];
                shifts.add(new Shift__c(
                    Session__c = session.Id,
                    Start_Time__c = Time.newInstance(slot.startHour, slot.startMinute, 0, 0),
                    End_Time__c = Time.newInstance(slot.endHour, slot.endMinute, 0, 0)
                ));
            }
        }

        insert shifts;
        return shifts;
    }

    @TestVisible
    private static void assignShiftsWithOverlaps(List<Shift__c> shifts, List<User> users) {
        List<Shift__c> shiftsToUpdate = new List<Shift__c>();

        Integer userIndex = 0;
        for (Integer i = 0; i < Math.min(20, shifts.size()); i++) {
            shifts[i].User__c = users[Math.mod(userIndex, users.size())].Id;
            shiftsToUpdate.add(shifts[i]);
            userIndex++;
        }

        // Create 5 intentional overlaps by assigning overlapping shifts to same users
        for (Integer i = 0; i < 5 && (i * 2 + 1) < shifts.size() && i < users.size(); i++) {
            shifts[i * 2].User__c = users[i].Id;
            shifts[i * 2 + 1].User__c = users[i].Id;
            if (!shiftsToUpdate.contains(shifts[i * 2])) {
                shiftsToUpdate.add(shifts[i * 2]);
            }
            if (!shiftsToUpdate.contains(shifts[i * 2 + 1])) {
                shiftsToUpdate.add(shifts[i * 2 + 1]);
            }
        }

        update shiftsToUpdate;
    }

    private static String getLocationForType(String sessionType) {
        switch on sessionType {
            when 'Booth' { return 'Expo Hall - Booth 123'; }
            when 'Theatre' { return 'Main Theatre'; }
            when 'Keynote' { return 'Grand Ballroom'; }
            when 'Consultation' { return 'Meeting Room 2A'; }
            when 'SIC' { return 'Success Innovation Center'; }
            when 'Breakout' { return 'Breakout Room B'; }
            when else { return 'TBD'; }
        }
    }

    private class TimeSlot {
        Integer startHour;
        Integer startMinute;
        Integer endHour;
        Integer endMinute;

        TimeSlot(Integer startHour, Integer startMinute, Integer endHour, Integer endMinute) {
            this.startHour = startHour;
            this.startMinute = startMinute;
            this.endHour = endHour;
            this.endMinute = endMinute;
        }
    }
}
