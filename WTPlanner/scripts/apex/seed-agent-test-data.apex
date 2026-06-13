// Run with: sf apex run --file scripts/apex/seed-agent-test-data.apex --target-org <alias>
//
// Seeds a small but exhaustive dataset for testing the Staffing Assistant
// agent end-to-end. Designed to exercise every subagent path:
//   - my_schedule        (logged-in user has shifts assigned)
//   - find_shifts        (some shifts unclaimed and not frozen)
//   - check_overlaps     (logged-in user has overlapping shifts)
//   - team_view          (logged-in user owns sessions in different staffing states)
//   - claim_shift        (target a free shift)
//   - drop_shift         (target one of the user's own shifts)
//
// IMPORTANT: depends on `seed-agent-test-users.apex` being run first to
// create the two test staff users. Splitting users + permset assignment
// into a separate transaction avoids the mixed-DML restriction (setup
// objects vs non-setup objects in the same transaction).
//
// Idempotent: skips creation if Event "Agent Test Day" already exists.

if ([SELECT COUNT() FROM Event__c WHERE Name = 'Agent Test Day'] > 0) {
    System.debug('Agent test data already exists, skipping.');
    return;
}

Id me = UserInfo.getUserId();

List<User> staff = [
    SELECT Id FROM User
    WHERE Username LIKE 'agenttest1+%@worldtour.test'
       OR Username LIKE 'agenttest2+%@worldtour.test'
    ORDER BY Username
];
if (staff.size() < 2) {
    System.debug('ERROR: run scripts/apex/seed-agent-test-users.apex first.');
    return;
}
Id user1 = staff[0].Id;
Id user2 = staff[1].Id;

// user3 reuses an existing sysadmin (not the logged-in user) so we have a
// non-self owner for some sessions. Falls back to user1 if there is no
// other admin on the org.
Id user3 = user1;
List<User> existingAdmins = [
    SELECT Id FROM User
    WHERE Profile.Name = 'System Administrator' AND IsActive = true
      AND Id != :me
    LIMIT 1
];
if (!existingAdmins.isEmpty()) {
    user3 = existingAdmins[0].Id;
}

// ── 2. Event + non-frozen Session_Types ─────────────────────────────────
Event__c ev = new Event__c(Name = 'Agent Test Day');
insert ev;

Session_Type__c stBooth    = new Session_Type__c(Name = 'Demo Booth',    Event__c = ev.Id, Is_Frozen__c = false);
Session_Type__c stTheatre  = new Session_Type__c(Name = 'Demo Theatre',  Event__c = ev.Id, Is_Frozen__c = false);
Session_Type__c stKeynote  = new Session_Type__c(Name = 'Demo Keynote',  Event__c = ev.Id, Is_Frozen__c = false);
Session_Type__c stWorkshop = new Session_Type__c(Name = 'Demo Workshop', Event__c = ev.Id, Is_Frozen__c = false);
Session_Type__c stLab      = new Session_Type__c(Name = 'Demo Lab',      Event__c = ev.Id, Is_Frozen__c = false);
insert new List<Session_Type__c>{ stBooth, stTheatre, stKeynote, stWorkshop, stLab };

// ── 3. Sessions (owners assigned) ───────────────────────────────────────
Session__c sBooth    = new Session__c(Name = 'Booth — Agent Demo',    Session_Type__c = stBooth.Id,    Location__c = 'Hall A', Min_Shifts__c = 2, Max_Shifts__c = 2, session_owner__c = me);
Session__c sTheatre  = new Session__c(Name = 'Theatre — Agent Demo',  Session_Type__c = stTheatre.Id,  Location__c = 'Hall B', Min_Shifts__c = 2, Max_Shifts__c = 3, session_owner__c = me);
Session__c sKeynote  = new Session__c(Name = 'Keynote — Agent Demo',  Session_Type__c = stKeynote.Id,  Location__c = 'Hall C', Min_Shifts__c = 1, Max_Shifts__c = 4, session_owner__c = user3);
Session__c sWorkshop = new Session__c(Name = 'Workshop — Agent Demo', Session_Type__c = stWorkshop.Id, Location__c = 'Lab 1',  Min_Shifts__c = 1, Max_Shifts__c = 3, session_owner__c = user3);
Session__c sLab      = new Session__c(Name = 'Lab — Agent Demo',      Session_Type__c = stLab.Id,      Location__c = 'Lab 2',  Min_Shifts__c = 1, Max_Shifts__c = 2, session_owner__c = me);
insert new List<Session__c>{ sBooth, sTheatre, sKeynote, sWorkshop, sLab };

// ── 4. Shifts ───────────────────────────────────────────────────────────
//
// Layout (HH:mm 24h):
//
//   Booth (owner: me, Fully Staffed)
//     09:00-11:00  → me
//     11:00-13:00  → user1
//
//   Theatre (owner: me, Min Reached, 1 free)
//     10:00-12:00  → me           ← OVERLAP with Booth 09:00-11:00 (mine)
//     12:00-14:00  → user2
//     14:00-16:00  → free
//
//   Keynote (owner: user3, Needs Staff)
//     14:00-15:00  → me
//     14:00-15:00  → free          (same slot, second seat free)
//     15:00-16:00  → free
//     15:00-16:00  → user1
//
//   Workshop (owner: user3, Needs Staff)
//     16:00-17:00  → free
//     16:00-17:00  → free
//     17:00-18:00  → free
//
//   Lab (owner: me, Needs Staff)
//     09:00-10:30  → free
//     10:30-12:00  → free

List<Shift__c> shifts = new List<Shift__c>{
    new Shift__c(Session__c = sBooth.Id,    User__c = me,    Start_Time__c = Time.newInstance(9,0,0,0),  End_Time__c = Time.newInstance(11,0,0,0)),
    new Shift__c(Session__c = sBooth.Id,    User__c = user1, Start_Time__c = Time.newInstance(11,0,0,0), End_Time__c = Time.newInstance(13,0,0,0)),

    new Shift__c(Session__c = sTheatre.Id,  User__c = me,    Start_Time__c = Time.newInstance(10,0,0,0), End_Time__c = Time.newInstance(12,0,0,0)),
    new Shift__c(Session__c = sTheatre.Id,  User__c = user2, Start_Time__c = Time.newInstance(12,0,0,0), End_Time__c = Time.newInstance(14,0,0,0)),
    new Shift__c(Session__c = sTheatre.Id,  User__c = null,  Start_Time__c = Time.newInstance(14,0,0,0), End_Time__c = Time.newInstance(16,0,0,0)),

    new Shift__c(Session__c = sKeynote.Id,  User__c = me,    Start_Time__c = Time.newInstance(14,0,0,0), End_Time__c = Time.newInstance(15,0,0,0)),
    new Shift__c(Session__c = sKeynote.Id,  User__c = null,  Start_Time__c = Time.newInstance(14,0,0,0), End_Time__c = Time.newInstance(15,0,0,0)),
    new Shift__c(Session__c = sKeynote.Id,  User__c = null,  Start_Time__c = Time.newInstance(15,0,0,0), End_Time__c = Time.newInstance(16,0,0,0)),
    new Shift__c(Session__c = sKeynote.Id,  User__c = user1, Start_Time__c = Time.newInstance(15,0,0,0), End_Time__c = Time.newInstance(16,0,0,0)),

    new Shift__c(Session__c = sWorkshop.Id, User__c = null,  Start_Time__c = Time.newInstance(16,0,0,0), End_Time__c = Time.newInstance(17,0,0,0)),
    new Shift__c(Session__c = sWorkshop.Id, User__c = null,  Start_Time__c = Time.newInstance(16,0,0,0), End_Time__c = Time.newInstance(17,0,0,0)),
    new Shift__c(Session__c = sWorkshop.Id, User__c = null,  Start_Time__c = Time.newInstance(17,0,0,0), End_Time__c = Time.newInstance(18,0,0,0)),

    new Shift__c(Session__c = sLab.Id,      User__c = null,  Start_Time__c = Time.newInstance(9,0,0,0),  End_Time__c = Time.newInstance(10,30,0,0)),
    new Shift__c(Session__c = sLab.Id,      User__c = null,  Start_Time__c = Time.newInstance(10,30,0,0),End_Time__c = Time.newInstance(12,0,0,0))
};
insert shifts;

System.debug('Agent test data created:');
System.debug('  Event: ' + ev.Id);
System.debug('  5 sessions (3 owned by you), 14 shifts (3 yours, 6 free, 5 assigned to staff)');
System.debug('  Overlap (mine): Booth 09:00-11:00 ↔ Theatre 10:00-12:00');
System.debug('Done. Run the agent preview and explore.');
