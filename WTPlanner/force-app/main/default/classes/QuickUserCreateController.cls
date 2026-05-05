public without sharing class QuickUserCreateController {

    @AuraEnabled
    public static UserResult createStaffingUser(String firstName, String lastName, String email) {
        if (!ShiftMarketplaceController.isCurrentUserAdmin()) {
            throw buildException('Admin privileges required');
        }

        if (String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(email)) {
            throw buildException('First Name, Last Name, and Email are required');
        }

        if (!email.trim().toLowerCase().endsWith('@salesforce.com')) {
            throw buildException('Only @salesforce.com email addresses are allowed');
        }

        try {
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
                SELECT Id, Name FROM PermissionSet
                WHERE Name = 'Staffing_App_Employee'
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

            resetPasswordAsync(newUser.Id);

            return new UserResult(newUser.Id, firstName.trim() + ' ' + lastName.trim(), baseUsername);
        } catch (DmlException e) {
            if (e.getMessage().contains('DUPLICATE_USERNAME')) {
                throw buildException('A user with this username already exists. Try a different name or email.');
            }
            throw buildException(e.getMessage());
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw buildException('Error creating user: ' + e.getMessage());
        }
    }

    @future
    public static void resetPasswordAsync(Id userId) {
        System.resetPassword(userId, true);
    }

    private static AuraHandledException buildException(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }

    public class UserResult {
        @AuraEnabled public String userId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String username { get; set; }

        public UserResult(Id userId, String name, String username) {
            this.userId = String.valueOf(userId);
            this.name = name;
            this.username = username;
        }
    }
}
