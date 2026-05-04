import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRosterData from '@salesforce/apex/AdminRosterController.getRosterData';

export default class AdminMasterRoster extends LightningElement {
    @track activeTab = 'byPerson';
    @track isLoading = false;

    // Raw data from Apex
    allRows = [];
    allShifts = [];
    allTimeSlots = [];

    // Filter values
    @track filterSessionType = '';
    @track filterSession = '';
    @track filterMinStaffing = '';
    @track filterOverlaps = '';
    @track filterTimeSlot = '';
    @track filterUser = '';

    // Filter options (built from data)
    @track sessionTypeOptions = [{ label: 'All Types', value: '' }];
    @track sessionOptions = [{ label: 'All Sessions', value: '' }];
    @track timeSlotFilterOptions = [{ label: 'All Time Slots', value: '' }];

    minStaffingOptions = [
        { label: 'All', value: '' },
        { label: 'Yes - Min reached', value: 'yes' },
        { label: 'No - Needs staff', value: 'no' }
    ];

    overlapOptions = [
        { label: 'All', value: '' },
        { label: 'Yes - Has overlaps', value: 'yes' },
        { label: 'No - No overlaps', value: 'no' }
    ];

    wiredResult;

    @wire(getRosterData)
    wiredRoster(result) {
        this.wiredResult = result;
        if (result.data) {
            this.allRows = result.data.rows || [];
            this.allShifts = result.data.shifts || [];
            this.allTimeSlots = result.data.timeSlots || [];

            // Build filter options
            this.sessionTypeOptions = [{ label: 'All Types', value: '' }];
            (result.data.sessionTypes || []).forEach(t => {
                this.sessionTypeOptions.push({ label: t, value: t });
            });

            this.sessionOptions = [{ label: 'All Sessions', value: '' }];
            (result.data.sessionNames || []).forEach(n => {
                this.sessionOptions.push({ label: n, value: n });
            });

            this.timeSlotFilterOptions = [{ label: 'All Time Slots', value: '' }];
            (result.data.timeSlotOptions || []).forEach(s => {
                this.timeSlotFilterOptions.push({ label: s, value: s });
            });
        } else if (result.error) {
            this.showToast('Error', 'Error loading roster data', 'error');
        }
    }

    // Filter handlers
    handleFilterSessionType(event) {
        this.filterSessionType = event.detail.value;
    }

    handleFilterSession(event) {
        this.filterSession = event.detail.value;
    }

    handleFilterMinStaffing(event) {
        this.filterMinStaffing = event.detail.value;
    }

    handleFilterOverlaps(event) {
        this.filterOverlaps = event.detail.value;
    }

    handleFilterTimeSlot(event) {
        this.filterTimeSlot = event.detail.value;
    }

    handleFilterUser(event) {
        this.filterUser = event.target.value;
    }

    handleClearFilters() {
        this.filterSessionType = '';
        this.filterSession = '';
        this.filterMinStaffing = '';
        this.filterOverlaps = '';
        this.filterTimeSlot = '';
        this.filterUser = '';
    }

    // Cell-level filter check — does this cell detail pass the current filters?
    cellPassesFilter(detail) {
        if (!detail) return false;
        if (this.filterSessionType && detail.sessionType !== this.filterSessionType) return false;
        if (this.filterSession && detail.sessionName !== this.filterSession) return false;
        if (this.filterMinStaffing === 'yes' && !detail.minReached) return false;
        if (this.filterMinStaffing === 'no' && detail.minReached) return false;
        if (this.filterOverlaps === 'yes' && !detail.sessionHasOverlap) return false;
        if (this.filterOverlaps === 'no' && detail.sessionHasOverlap) return false;
        return true;
    }

    // Shift-level filter check for By Shift tab
    shiftPassesFilter(shift) {
        if (this.filterSessionType && shift.sessionType !== this.filterSessionType) return false;
        if (this.filterSession && shift.sessionName !== this.filterSession) return false;
        if (this.filterTimeSlot && shift.timeSlot !== this.filterTimeSlot) return false;
        if (this.filterMinStaffing === 'yes' && !shift.minReached) return false;
        if (this.filterMinStaffing === 'no' && shift.minReached) return false;
        if (this.filterOverlaps === 'yes' && !shift.sessionHasOverlap) return false;
        if (this.filterOverlaps === 'no' && shift.sessionHasOverlap) return false;
        if (this.filterUser) {
            const search = this.filterUser.toLowerCase();
            const name = (shift.assignedUserName || '').toLowerCase();
            if (!name.includes(search)) return false;
        }
        return true;
    }

    // Computed: filtered time slots for By Person (hide columns if time slot filter active)
    get timeSlots() {
        if (this.filterTimeSlot) {
            return this.allTimeSlots.filter(s => s === this.filterTimeSlot);
        }
        return this.allTimeSlots;
    }

    // Computed: filtered person rows
    get personRows() {
        const slots = this.timeSlots;
        const userSearch = this.filterUser ? this.filterUser.toLowerCase() : '';

        const result = [];
        for (const row of this.allRows) {
            // User name filter
            if (userSearch && !row.userName.toLowerCase().includes(userSearch)) continue;

            const slotCells = slots.map(slot => {
                const hasRawValue = !!(row.cells && row.cells[slot]);
                const detailsList = row.cellDetailsList ? row.cellDetailsList[slot] : null;
                const details = detailsList || [];
                const anyPassesFilter = hasRawValue && details.some(d => this.cellPassesFilter(d));

                const items = details.filter(d => this.cellPassesFilter(d)).map((detail, idx) => {
                    let statusClass = '';
                    if (detail.status === 'Needs Staff') {
                        statusClass = 'popover-status-danger';
                    } else if (detail.status === 'Fully Staffed') {
                        statusClass = 'popover-status-muted';
                    } else {
                        statusClass = 'popover-status-success';
                    }
                    const badgeLabel = detail.sessionType
                        ? `${detail.sessionName} (${detail.sessionType})`
                        : detail.sessionName;

                    return {
                        key: row.userName + '-' + slot + '-' + idx,
                        value: detail.sessionName,
                        badgeLabel,
                        sessionType: detail.sessionType || '',
                        timeRange: detail.timeRange || '',
                        location: detail.location || '',
                        staffingLabel: detail.staffingLabel || '',
                        status: detail.status || '',
                        statusClass,
                        hasOverlap: detail.hasOverlap || false
                    };
                });

                return {
                    key: row.userName + '-' + slot,
                    slot,
                    hasValue: anyPassesFilter,
                    items,
                    hasOverlap: items.some(i => i.hasOverlap)
                };
            });

            // Only include row if at least one cell is visible
            if (slotCells.some(c => c.hasValue)) {
                result.push({ ...row, slotCells });
            }
        }
        return result;
    }

    // Computed: filtered shifts for By Shift tab
    get filteredShifts() {
        return this.allShifts.filter(s => this.shiftPassesFilter(s));
    }

    handleTabChange(event) {
        this.activeTab = event.target.value;
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredResult).finally(() => {
            this.isLoading = false;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get hasPersonRoster() {
        return this.personRows.length > 0;
    }

    get hasShiftRoster() {
        return this.filteredShifts.length > 0;
    }

    handlePopoverShow(event) {
        const container = event.currentTarget;
        const popover = container.querySelector('.popover-content');
        if (!popover) return;

        const rect = container.getBoundingClientRect();
        popover.style.left = rect.left + rect.width / 2 + 'px';
        popover.style.transform = 'translateX(-50%)';
        popover.style.top = rect.bottom + 8 + 'px';
    }

    handlePopoverHide() {
        // CSS handles hide via .popover-container:hover
    }

    get hasActiveFilters() {
        return !!(this.filterSessionType || this.filterSession ||
            this.filterMinStaffing || this.filterOverlaps ||
            this.filterTimeSlot || this.filterUser);
    }
}
