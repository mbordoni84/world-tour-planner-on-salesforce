module.exports = [
    {
        files: ['**/*.js'],
        ...require('@salesforce/eslint-config-lwc/recommended'),
        rules: {
            // Add custom rules here if needed
        }
    },
    {
        files: ['**/lwc/**/*.js'],
        ...require('@salesforce/eslint-config-lwc/recommended'),
        rules: {
            // LWC specific rules
        }
    },
    {
        files: ['**/__tests__/**/*.js'],
        ...require('@salesforce/eslint-config-lwc/jest'),
        rules: {
            // Jest specific rules
        }
    }
];
