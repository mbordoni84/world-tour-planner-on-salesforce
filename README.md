# World Tour Planner - Salesforce Project

A comprehensive Salesforce Lightning Web Components (LWC) project for managing world tour planning activities.

## Project Overview

This project provides tools and components for organizing and managing world tour events, locations, and related activities within the Salesforce ecosystem.

## Project Structure

```
world-tour-planner/
├── force-app/              # Salesforce source code
│   └── main/
│       └── default/
│           ├── classes/     # Apex classes
│           ├── lwc/         # Lightning Web Components
│           ├── objects/     # Custom objects and fields
│           └── triggers/    # Apex triggers
├── .sfdx/                  # Salesforce CLI cache
├── .sf/                    # Salesforce CLI configuration
├── .vscode/                # VS Code settings
└── package.json            # Node.js dependencies
```

## Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli)
- [Node.js](https://nodejs.org) (LTS version recommended)
- [Git](https://git-scm.com)
- [VS Code](https://code.visualstudio.com) with Salesforce Extension Pack

## Setup Instructions

### 1. Clone and Setup
```bash
git clone <your-repository-url>
cd world-tour-planner-on-salesforce
npm install
```

### 2. Salesforce Org Authentication
```bash
# Authenticate with your Dev Hub (for scratch orgs)
sf org login web --set-default-dev-hub

# OR authenticate with an existing org
sf org login web --set-default --alias your-org-alias
```

### 3. Create Scratch Org (Optional)
```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias world-tour-scratch --set-default
```

### 4. Deploy Source Code
```bash
# For scratch org
sf project deploy start

# For sandbox/production org
sf project deploy start --target-org your-org-alias
```

## Development Commands

### Code Quality
```bash
# Run ESLint
npm run lint

# Format code with Prettier
npm run prettier

# Verify formatting
npm run prettier:verify
```

### Testing
```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:unit:watch

# Run tests with coverage
npm run test:unit:coverage

# Debug tests
npm run test:unit:debug
```

### Salesforce Operations
```bash
# Push source to scratch org
sf project deploy start

# Pull changes from org
sf project retrieve start

# Open org in browser
sf org open

# View org info
sf org display
```

## Code Standards

- **Apex**: Follow Salesforce best practices, use proper bulkification and security
- **LWC**: Use Lightning Data Service (LDS) when possible, follow component lifecycle
- **Testing**: Maintain >75% code coverage, write meaningful tests
- **Documentation**: Use JSDoc for JavaScript, ApexDoc for Apex classes

## API Version

This project uses Salesforce API version **64.0** (Winter '25).

## Contributing

1. Create a feature branch from `main`
2. Make your changes following the code standards
3. Run tests and ensure they pass
4. Format code with Prettier
5. Submit a pull request

## Resources

- [Salesforce Developer Documentation](https://developer.salesforce.com/docs/)
- [Lightning Web Components Documentation](https://lwc.dev/)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)
- [Trailhead Learning Platform](https://trailhead.salesforce.com/)

## License

This project is for educational and demonstration purposes.
