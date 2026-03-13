# Partner Performance Dashboard Specification

## 1) Scope

The overall goal is to create a Partner Performance Dashboard built as a Lightning Web Component that provides visibility into partner account performance through KPI summary tiles and a sortable detail table. This dashboard will help track partner effectiveness across leads, opportunities, and revenue metrics.

Main deliverables:
- One new dashboard Lightning Web Component (partnerPerformanceDashboard)
- One Apex service class (PartnerPerformanceService) 
- One new Custom Tab for the dashboard ("Partner Performance")
- Updates to the existing Partner_Management permission set

## 2) Data Model

The dashboard will leverage existing Account, Lead, and Opportunity objects to measure partner performance using these existing fields:

**Account Object Fields:**
- `IsPartner` - to identify partner accounts
- `Partner_Program_Level__c` - for Tier (Platinum, Gold, Silver, Bronze)
- `Name` - for Partner name
- `Number_Leads_Total__c` - for total leads count
- `Number_Leads_Converted__c` - for converted leads
- `Number_Closed_Won_Opportunities__c` - for won opportunities count
- `Number_Closed_Opportunities__c` - for total opportunities
- `Value_Closed_Won_Opportunties__c` - for revenue data
- `Lead_Conversion_Rate__c` - for conversion metrics
- `Opportunity_Win_Rate__c` - for win rate metrics

**Record Type:**
- `SDO_Account_Partner` record type will be used to filter partner accounts

**Assumptions:** 
- If a "Partner_Account" record type exists (mentioned in compact layout), it will be included in filtering
- The existing rollup fields on Account provide accurate aggregated data from Leads and Opportunities

## 3) LWC

The new `partnerPerformanceDashboard` Lightning Web Component will:

**Target:** `lightning__Tab` - designed to run as a standalone tab

**UI Structure:**
- Header section with dashboard title and refresh functionality
- KPI tiles section using `lightning-card` components showing:
  - Total Partners
  - Total Revenue
  - Average Win Rate
  - Top Performing Tier
- Data table section using `lightning-datatable` with sortable columns:
  - Rank (calculated)
  - Partner (Account Name)
  - Tier (Partner Program Level)
  - Leads (Total Leads)
  - Converted (Converted Leads) 
  - Opps (Total Opportunities)
  - Won (Won Opportunities)
  - Revenue (Closed Won Value)
  - Win Rate (%)

**Data Integration:**
- Uses `@wire` decorator to call `PartnerPerformanceService.getPartnerMetrics()` 
- Implements reactive data updates and automatic refresh

**State Management:**
- Loading state: Shows spinner while data loads
- Empty state: Displays "No partner data available" message when no records found
- Error state: Shows user-friendly error message with retry option
- Success state: Displays populated KPI tiles and data table

## 4) Custom Tab

**New Custom Tab Configuration:**
- **Label:** "Partner Performance"
- **API Name:** `Partner_Performance`
- **Icon:** Chart-style icon (standard:analytics or similar)
- **Target:** Points to the `partnerPerformanceDashboard` Lightning Web Component
- **Visibility:** Available to users with appropriate permissions
- **Mobile Ready:** Enabled for mobile access

## 5) Permission Set

**Updates to existing `Partner_Management` permission set:**

**Object Permissions:**
- Maintain existing Account read permissions
- Ensure field-level access to all dashboard fields:
  - `IsPartner`
  - `Partner_Program_Level__c`
  - `Name`
  - `Number_Leads_Total__c`
  - `Number_Leads_Converted__c` 
  - `Number_Closed_Won_Opportunities__c`
  - `Number_Closed_Opportunities__c`
  - `Value_Closed_Won_Opportunties__c`
  - `Lead_Conversion_Rate__c`
  - `Opportunity_Win_Rate__c`

**Apex Class Access:**
- Add permission for `PartnerPerformanceService` class

**Lightning Component Access:**
- Add permission for `partnerPerformanceDashboard` component

**Tab Visibility:**
- Grant access to `Partner_Performance` custom tab

**Record Type Access:**
- Include visibility to `SDO_Account_Partner` record type
- **Assumption:** If `Partner_Account` record type exists, include visibility to it as well

## 6) Apex Service

**Class: `PartnerPerformanceService`**

**Structure:**
```apex
public with sharing class PartnerPerformanceService {
    
    @AuraEnabled(cacheable=true)
    public static List<PartnerMetric> getPartnerMetrics() {
        // Implementation details
    }
    
    // Wrapper class for partner metrics
    public class PartnerMetric {
        @AuraEnabled public Integer rank;
        @AuraEnabled public String partnerId;
        @AuraEnabled public String partnerName;
        @AuraEnabled public String tier;
        @AuraEnabled public Integer totalLeads;
        @AuraEnabled public Integer convertedLeads;
        @AuraEnabled public Integer totalOpportunities;
        @AuraEnabled public Integer wonOpportunities;
        @AuraEnabled public Decimal revenue;
        @AuraEnabled public Decimal winRate;
        @AuraEnabled public Decimal conversionRate;
    }
}
```

**Query Logic:**
- Query Accounts where `IsPartner = true` and `RecordType.DeveloperName = 'SDO_Account_Partner'`
- Select all necessary fields for dashboard metrics
- Apply `WITH USER_MODE` for field-level security enforcement
- Calculate derived metrics (conversion rates, rankings)

**Data Processing:**
- Aggregate partner performance data
- Calculate rankings based on revenue or won opportunities
- Sort results by performance metrics (highest revenue first)
- Handle null values and edge cases
- Implement proper exception handling with user-friendly error messages

This plan leverages all existing fields and metadata, requires no new custom fields, and provides a comprehensive partner performance tracking solution.
