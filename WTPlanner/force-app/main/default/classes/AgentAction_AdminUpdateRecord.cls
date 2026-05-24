public with sharing class AgentAction_AdminUpdateRecord {

    public class Request {
        @InvocableVariable(label='Object Type' description='API name of the object: Session__c, Shift__c, Session_Type__c, or Event__c' required=true)
        public String objectType;
        @InvocableVariable(label='Record ID' description='The Salesforce ID of the record to update' required=true)
        public String recordId;
        @InvocableVariable(label='Field Name' description='API name of the field to update (e.g., Name, Location__c, Is_Frozen__c)' required=true)
        public String fieldName;
        @InvocableVariable(label='New Value' description='The new value to set on the field' required=true)
        public String newValue;
        @InvocableVariable(label='Confirmed' description='Set to True to execute, False for preview only' required=true)
        public Boolean confirmed;
    }

    public class Result {
        @InvocableVariable(label='Message' description='Result of the operation')
        public String message;
        @InvocableVariable(label='Success' description='Whether the operation succeeded')
        public Boolean success;
    }

    private static final Set<String> ALLOWED_OBJECTS = new Set<String>{
        'Session__c', 'Shift__c', 'Session_Type__c', 'Event__c'
    };

    @InvocableMethod(label='Admin Update Record' description='Updates a field on a staffing record. Write access is enforced by field-level security.' category='Staffing')
    public static List<Result> execute(List<Request> requests) {
        Request req = requests[0];
        Result result = new Result();

        // Validate object type
        if (!ALLOWED_OBJECTS.contains(req.objectType)) {
            result.message = 'Invalid object type "' + req.objectType + '". Allowed: Session__c, Shift__c, Session_Type__c, Event__c.';
            result.success = false;
            return new List<Result>{ result };
        }

        // Preview mode
        if (!req.confirmed) {
            result.message = 'Preview: Update ' + req.objectType + ' [' + req.recordId + '], set ' + req.fieldName + ' = "' + req.newValue + '". Please confirm to proceed.';
            result.success = true;
            return new List<Result>{ result };
        }

        // Execute update
        try {
            SObject record = Schema.getGlobalDescribe().get(req.objectType).newSObject(Id.valueOf(req.recordId));

            Schema.DescribeFieldResult fieldDescribe = Schema.getGlobalDescribe()
                .get(req.objectType)
                .getDescribe()
                .fields.getMap()
                .get(req.fieldName)
                .getDescribe();

            Object typedValue = convertValue(req.newValue, fieldDescribe.getType());
            record.put(req.fieldName, typedValue);
            update record;

            result.message = 'Successfully updated ' + req.objectType + ' [' + req.recordId + ']: ' + req.fieldName + ' = "' + req.newValue + '".';
            result.success = true;
        } catch (Exception e) {
            result.message = 'Failed to update: ' + e.getMessage();
            result.success = false;
        }

        return new List<Result>{ result };
    }

    private static Object convertValue(String value, Schema.DisplayType fieldType) {
        if (value == null || value == 'null') return null;
        switch on fieldType {
            when BOOLEAN {
                return Boolean.valueOf(value);
            }
            when DOUBLE, CURRENCY, PERCENT {
                return Decimal.valueOf(value);
            }
            when INTEGER {
                return Integer.valueOf(value);
            }
            when DATE {
                return Date.valueOf(value);
            }
            when DATETIME {
                return Datetime.valueOf(value);
            }
            when else {
                return value;
            }
        }
    }
}
