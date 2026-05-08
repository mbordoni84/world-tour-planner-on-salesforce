@RestResource(urlMapping='/staffing/user/create')
global without sharing class StaffingAPI_CreateUser {
    @HttpPost
    global static void doPost() {
        RestResponse res = RestContext.response;
        try {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(
                RestContext.request.requestBody.toString()
            );
            String firstName = (String) body.get('firstName');
            String lastName = (String) body.get('lastName');
            String email = (String) body.get('email');

            if (String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(email)) {
                sendError(res, 400, 'First Name, Last Name, and Email are required.');
                return;
            }

            if (!email.trim().toLowerCase().endsWith('@salesforce.com')) {
                sendError(res, 400, 'Only @salesforce.com email addresses are allowed.');
                return;
            }

            List<User> existing = [
                SELECT Id, Username FROM User WHERE Email = :email.trim() AND IsActive = true LIMIT 1
            ];
            if (!existing.isEmpty()) {
                try {
                    QuickUserCreateController.resetPasswordAsync(existing[0].Id);
                } catch (Exception resetEx) {
                    // Non-blocking
                }
                res.statusCode = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    new Map<String, Object>{
                        'success' => false,
                        'error' => 'DUPLICATE_EMAIL',
                        'username' => existing[0].Username,
                        'email' => email.trim()
                    }
                ));
                return;
            }

            if (!ShiftMarketplaceController.isCurrentUserAdmin()) {
                sendError(res, 403, 'Admin privileges required to create users.');
                return;
            }

            Profile standardProfile = [
                SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1
            ];

            String orgId = UserInfo.getOrganizationId();
            String baseUsername = firstName.toLowerCase().replaceAll('[^a-z]', '')
                + '.' + lastName.toLowerCase().replaceAll('[^a-z]', '')
                + '.' + String.valueOf(System.currentTimeMillis())
                + '@staffingapp.' + orgId + '.sfdc';

            String alias = (firstName.substring(0, Math.min(firstName.length(), 7))
                + lastName.substring(0, 1)).substring(0, Math.min(8,
                    firstName.substring(0, Math.min(firstName.length(), 7)).length()
                    + 1));

            User newUser = new User(
                FirstName = firstName.trim(),
                LastName = lastName.trim(),
                Email = email.trim(),
                Username = baseUsername,
                Alias = alias,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = standardProfile.Id,
                IsActive = true
            );
            insert newUser;

            List<PermissionSet> permSets = [
                SELECT Id FROM PermissionSet WHERE Name = 'Staffing_App_Employee'
            ];
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (PermissionSet ps : permSets) {
                assignments.add(new PermissionSetAssignment(
                    AssigneeId = newUser.Id,
                    PermissionSetId = ps.Id
                ));
            }
            if (!assignments.isEmpty()) {
                insert assignments;
            }

            try {
                QuickUserCreateController.resetPasswordAsync(newUser.Id);
            } catch (Exception resetEx) {
                // Non-blocking: user is created, password reset will be handled manually
            }

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(
                new Map<String, Object>{
                    'success' => true,
                    'userId' => String.valueOf(newUser.Id),
                    'name' => firstName.trim() + ' ' + lastName.trim(),
                    'username' => baseUsername
                }
            ));
        } catch (DmlException e) {
            if (e.getMessage().contains('DUPLICATE_USERNAME')) {
                sendError(res, 400, 'A user with this username already exists. Try a different name.');
            } else {
                sendError(res, 400, e.getMessage());
            }
        } catch (Exception e) {
            sendError(res, 500, e.getMessage());
        }
    }

    private static void sendError(RestResponse res, Integer statusCode, String message) {
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(
            new Map<String, Object>{ 'success' => false, 'error' => message }
        ));
    }
}
