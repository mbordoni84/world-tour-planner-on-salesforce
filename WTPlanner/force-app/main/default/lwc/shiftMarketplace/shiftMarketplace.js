import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSessionsNeedingStaff from '@salesforce/apex/ShiftMarketplaceController.getSessionsNeedingStaff';
import getMyShifts from '@salesforce/apex/ShiftMarketplaceController.getMyShifts';
import claimShift from '@salesforce/apex/ShiftMarketplaceController.claimShift';
import checkOverlap from '@salesforce/apex/ShiftMarketplaceController.checkOverlap';

export default class ShiftMarketplace extends LightningElement {
    @track sessions = [];
    @track filteredSessions = [];
    @track myShiftIds = new Set();
    @track expandedSessionId = null;
    @track isLoading = false;

    // Filters
    @track selectedSessionType = '';
    @track selectedLocation = '';
    @track selectedStatus = '';
    @track searchText = '';
    @track hideFullyStaffed = false;

    // Filter options (built dynamically from data)
    @track sessionTypeOptions = [{ label: 'All Types', value: '' }];
    @track locationOptions = [{ label: 'All Locations', value: '' }];
    statusOptions = [
        { label: 'All Statuses', value: '' },
        { label: 'Needs Staff', value: 'needsStaff' },
        { label: 'Open', value: 'open' },
        { label: 'Fully Staffed', value: 'full' }
    ];

    wiredSessionsResult;
    wiredMyShiftsResult;

    @wire(getSessionsNeedingStaff)
    wiredSessions(result) {
        this.wiredSessionsResult = result;
        if (result.data) {
            const typeSet = new Set();
            const locationSet = new Set();

            this.sessions = result.data.map(session => {
                if (session.sessionType) typeSet.add(session.sessionType);
                if (session.location) locationSet.add(session.location);

                return {
                    ...session,
                    isExpanded: session.id === this.expandedSessionId,
                    expandIcon: session.id === this.expandedSessionId ? 'utility:chevronup' : 'utility:chevrondown',
                    statusClass: this.getStatusClass(session),
                    statusKey: this.getStatusKey(session),
                    hasUnclaimed: session.availableShifts > 0,
                    shifts: session.shifts.map(shift => ({
                        ...shift,
                        isMyShift: shift.assignedUserName && this.myShiftIds.has(shift.id),
                        statusIcon: shift.isClaimed ? 'utility:check' : 'utility:dash',
                        statusVariant: shift.isClaimed ? 'success' : ''
                    }))
                };
            });

            // Build filter options from data
            this.sessionTypeOptions = [{ label: 'All Types', value: '' }];
            [...typeSet].sort().forEach(t => {
                this.sessionTypeOptions.push({ label: t, value: t });
            });

            this.locationOptions = [{ label: 'All Locations', value: '' }];
            [...locationSet].sort().forEach(l => {
                this.locationOptions.push({ label: l, value: l });
            });

            this.applyFilters();
        } else if (result.error) {
            this.showToast('Error', 'Error loading sessions', 'error');
        }
    }

    @wire(getMyShifts)
    wiredMyShifts(result) {
        this.wiredMyShiftsResult = result;
        if (result.data) {
            this.myShiftIds = new Set(result.data.map(s => s.id));
            this.updateMyShiftStatus();
        }
    }

    updateMyShiftStatus() {
        this.sessions = this.sessions.map(session => ({
            ...session,
            shifts: session.shifts.map(shift => ({
                ...shift,
                isMyShift: this.myShiftIds.has(shift.id),
                statusIcon: shift.isClaimed ? 'utility:check' : 'utility:dash',
                statusVariant: shift.isClaimed ? 'success' : ''
            }))
        }));
        this.applyFilters();
    }

    getStatusClass(session) {
        if (session.needsStaff) return 'session-card status-needs-staff';
        if (session.isFull) return 'session-card status-full';
        return 'session-card status-open';
    }

    getStatusKey(session) {
        if (session.needsStaff) return 'needsStaff';
        if (session.isFull) return 'full';
        return 'open';
    }

    // Filter handlers
    handleSessionTypeChange(event) {
        this.selectedSessionType = event.detail.value;
        this.applyFilters();
    }

    handleLocationChange(event) {
        this.selectedLocation = event.detail.value;
        this.applyFilters();
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        this.applyFilters();
    }

    handleSearchChange(event) {
        this.searchText = event.target.value;
        this.applyFilters();
    }

    handleHideFullyStaffedChange(event) {
        this.hideFullyStaffed = event.target.checked;
        this.applyFilters();
    }

    handleClearFilters() {
        this.selectedSessionType = '';
        this.selectedLocation = '';
        this.selectedStatus = '';
        this.searchText = '';
        this.hideFullyStaffed = false;
        this.applyFilters();
    }

    applyFilters() {
        const search = this.searchText ? this.searchText.toLowerCase() : '';
        this.filteredSessions = this.sessions.filter(session => {
            if (this.selectedSessionType && session.sessionType !== this.selectedSessionType) return false;
            if (this.selectedLocation && session.location !== this.selectedLocation) return false;
            if (this.selectedStatus && session.statusKey !== this.selectedStatus) return false;
            if (this.hideFullyStaffed && session.isFull) return false;
            if (search && !session.name.toLowerCase().includes(search)) return false;
            return true;
        });
    }

    handleSessionClick(event) {
        const sessionId = event.currentTarget.dataset.id;
        this.toggleSession(sessionId);
    }

    handleViewShifts(event) {
        event.stopPropagation();
        const sessionId = event.currentTarget.dataset.id;
        this.toggleSession(sessionId);
    }

    toggleSession(sessionId) {
        this.expandedSessionId = this.expandedSessionId === sessionId ? null : sessionId;
        this.sessions = this.sessions.map(s => ({
            ...s,
            isExpanded: s.id === this.expandedSessionId,
            expandIcon: s.id === this.expandedSessionId ? 'utility:chevronup' : 'utility:chevrondown'
        }));
        this.applyFilters();
    }

    async handleClaimShift(event) {
        event.stopPropagation();
        const shiftId = event.target.dataset.shiftId;
        this.isLoading = true;

        try {
            const overlapResult = await checkOverlap({ shiftId });

            if (overlapResult.hasOverlap) {
                const proceed = confirm(`Warning: ${overlapResult.message}\n\nDo you want to continue?`);
                if (!proceed) {
                    this.isLoading = false;
                    return;
                }
            }

            await claimShift({ shiftId });
            this.showToast('Success', 'Shift claimed successfully!', 'success');
            await this.refreshAll();
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error claiming shift', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async refreshAll() {
        await Promise.all([
            refreshApex(this.wiredSessionsResult),
            refreshApex(this.wiredMyShiftsResult)
        ]);
    }

    handleRefresh() {
        this.isLoading = true;
        this.refreshAll().finally(() => {
            this.isLoading = false;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get hasSessions() {
        return this.filteredSessions.length > 0;
    }

    get sessionsNeedingStaffCount() {
        return this.sessions.filter(s => s.needsStaff).length;
    }

    get hasActiveFilters() {
        return !!(this.selectedSessionType || this.selectedLocation ||
            this.selectedStatus || this.searchText || this.hideFullyStaffed);
    }
}
