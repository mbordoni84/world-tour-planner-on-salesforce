import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getDashboardData from '@salesforce/apex/StaffingDashboardController.getDashboardData';

const SESSION_COLUMNS = [
    { label: 'Session', fieldName: 'name', sortable: true },
    { label: 'Type', fieldName: 'sessionType', sortable: true },
    { label: 'Location', fieldName: 'location', sortable: true },
    { label: 'Time Range', fieldName: 'timeRange', sortable: true },
    { label: 'Staffing', fieldName: 'staffingLabel', sortable: true },
    {
        label: 'Status',
        fieldName: 'status',
        sortable: true,
        cellAttributes: { class: { fieldName: 'statusCellClass' } }
    }
];

const OVERLAP_COLUMNS = [
    { label: 'Employee', fieldName: 'userName' },
    { label: 'Session 1', fieldName: 'session1' },
    { label: 'Time 1', fieldName: 'time1' },
    { label: 'Session 2', fieldName: 'session2' },
    { label: 'Time 2', fieldName: 'time2' }
];

export default class StaffingDashboard extends LightningElement {
    @track summary = {};
    @track allSessions = [];
    @track filteredSessions = [];
    @track overlaps = [];
    @track leaderboard = [];
    @track isLoading = true;
    @track overlapExpanded = true;

    // Filters
    @track selectedSessionType = '';
    @track selectedTimeSlot = '';
    @track selectedStatus = '';

    // Filter options (populated from data)
    sessionTypeOptions = [{ label: 'All Types', value: '' }];
    timeSlotOptions = [{ label: 'All Time Slots', value: '' }];
    statusOptions = [
        { label: 'All Statuses', value: '' },
        { label: 'Needs Staff', value: 'Needs Staff' },
        { label: 'Min Reached', value: 'Min Reached' },
        { label: 'Fully Staffed', value: 'Fully Staffed' }
    ];

    // Sorting
    sortedBy = 'name';
    sortDirection = 'asc';

    sessionColumns = SESSION_COLUMNS;
    overlapColumns = OVERLAP_COLUMNS;

    wiredResult;

    @wire(getDashboardData)
    wiredDashboard(result) {
        this.wiredResult = result;
        this.isLoading = false;
        if (result.data) {
            this.summary = result.data.summary;
            this.overlaps = result.data.overlaps || [];
            this.leaderboard = (result.data.leaderboard || []).map(e => ({
                ...e,
                medal: e.rank === 1 ? '1st' : e.rank === 2 ? '2nd' : e.rank === 3 ? '3rd' : String(e.rank),
                isTopThree: e.rank <= 3
            }));

            this.allSessions = (result.data.sessions || []).map(s => ({
                ...s,
                staffingLabel: s.claimed + ' / ' + s.minShifts + ' min (' + s.maxShifts + ' max)',
                statusCellClass: this.getStatusCellClass(s.status)
            }));

            // Build filter options from data
            this.sessionTypeOptions = [{ label: 'All Types', value: '' }];
            (result.data.sessionTypes || []).forEach(t => {
                this.sessionTypeOptions.push({ label: t, value: t });
            });

            this.timeSlotOptions = [{ label: 'All Time Slots', value: '' }];
            (result.data.timeSlots || []).forEach(t => {
                this.timeSlotOptions.push({ label: t, value: t });
            });

            this.applyFilters();
        }
    }

    getStatusCellClass(status) {
        switch (status) {
            case 'Needs Staff': return 'slds-text-color_error';
            case 'Min Reached': return 'slds-text-color_success';
            case 'Fully Staffed': return 'status-full-text';
            default: return '';
        }
    }

    // Filter handlers
    handleSessionTypeChange(event) {
        this.selectedSessionType = event.detail.value;
        this.applyFilters();
    }

    handleTimeSlotChange(event) {
        this.selectedTimeSlot = event.detail.value;
        this.applyFilters();
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        this.applyFilters();
    }

    applyFilters() {
        this.filteredSessions = this.allSessions.filter(s => {
            const matchesType = !this.selectedSessionType || s.sessionType === this.selectedSessionType;
            const matchesSlot = !this.selectedTimeSlot || s.timeRange === this.selectedTimeSlot;
            const matchesStatus = !this.selectedStatus || s.status === this.selectedStatus;
            return matchesType && matchesSlot && matchesStatus;
        });
        this.sortData(this.sortedBy, this.sortDirection);
    }

    // Sorting
    handleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortedBy, this.sortDirection);
    }

    sortData(fieldName, direction) {
        const data = [...this.filteredSessions];
        const reverse = direction === 'asc' ? 1 : -1;
        data.sort((a, b) => {
            const valA = a[fieldName] || '';
            const valB = b[fieldName] || '';
            if (typeof valA === 'number') {
                return reverse * (valA - valB);
            }
            return reverse * String(valA).localeCompare(String(valB));
        });
        this.filteredSessions = data;
    }

    // Refresh
    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredResult).finally(() => {
            this.isLoading = false;
        });
    }

    // Toggle overlap section
    toggleOverlaps() {
        this.overlapExpanded = !this.overlapExpanded;
    }

    // KPI tile click → scroll to overlaps
    handleOverlapTileClick() {
        if (!this.overlapExpanded) {
            this.overlapExpanded = true;
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            const el = this.template.querySelector('[data-id="overlap-section"]');
            if (el) {
                el.scrollIntoView({ behavior: 'smooth' });
            }
        }, 100);
    }

    // Getters
    get hasOverlaps() {
        return this.overlaps.length > 0;
    }

    get hasSessions() {
        return this.filteredSessions.length > 0;
    }

    get overlapToggleIcon() {
        return this.overlapExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get fillRateFormatted() {
        return this.summary.fillRate != null ? this.summary.fillRate + '%' : '0%';
    }

    get fillRateClass() {
        if (!this.summary.fillRate) return 'kpi-value';
        if (this.summary.fillRate >= 80) return 'kpi-value kpi-success';
        if (this.summary.fillRate >= 50) return 'kpi-value kpi-warning';
        return 'kpi-value kpi-danger';
    }

    get totalShiftsDisplay() {
        return this.summary.totalShifts || 0;
    }

    get assignedDisplay() {
        return this.summary.assigned || 0;
    }

    get unassignedDisplay() {
        return this.summary.unassigned || 0;
    }

    get overlapsDisplay() {
        return this.summary.overlaps || 0;
    }

    get hasLeaderboard() {
        return this.leaderboard.length > 0;
    }
}
