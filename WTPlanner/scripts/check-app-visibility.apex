// Check app visibility and profile assignments
List<AppMenuItem> appMenuItems = [
    SELECT Id, Name, Label, ApplicationId, IsAccessible, IsVisible
    FROM AppMenuItem
    WHERE Name = 'World_Tour_Staffing'
    LIMIT 1
];

System.debug('=== App Menu Items ===');
for (AppMenuItem item : appMenuItems) {
    System.debug('App: ' + item.Label);
    System.debug('IsAccessible: ' + item.IsAccessible);
    System.debug('IsVisible: ' + item.IsVisible);
    System.debug('ApplicationId: ' + item.ApplicationId);
}

// Check current user profile
User currentUser = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
System.debug('\n=== Current User ===');
System.debug('Name: ' + currentUser.Name);
System.debug('Profile: ' + currentUser.Profile.Name);

// Check permission set assignments
List<PermissionSetAssignment> psAssignments = [
    SELECT PermissionSet.Name, PermissionSet.Label
    FROM PermissionSetAssignment
    WHERE AssigneeId = :UserInfo.getUserId()
    AND PermissionSet.Name LIKE 'Staffing_App%'
];

System.debug('\n=== Permission Set Assignments ===');
for (PermissionSetAssignment psa : psAssignments) {
    System.debug('- ' + psa.PermissionSet.Label + ' (' + psa.PermissionSet.Name + ')');
}

System.debug('\n=== Instructions ===');
System.debug('To make the app visible:');
System.debug('1. Go to Setup → App Manager');
System.debug('2. Find "World Tour Staffing" app');
System.debug('3. Click dropdown → Edit');
System.debug('4. Go to "User Profiles" section');
System.debug('5. Add your profile (' + currentUser.Profile.Name + ') to the Selected Profiles');
System.debug('6. Save');
