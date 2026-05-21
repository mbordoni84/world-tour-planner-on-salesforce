import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSessionsNeedingStaff from '@salesforce/apex/ShiftMarketplaceController.getSessionsNeedingStaff';
import getMyShifts from '@salesforce/apex/ShiftMarketplaceController.getMyShifts';
import claimShift from '@salesforce/apex/ShiftMarketplaceController.claimShift';
import checkOverlap from '@salesforce/apex/ShiftMarketplaceController.checkOverlap';
import isCurrentUserAdmin from '@salesforce/apex/ShiftMarketplaceController.isCurrentUserAdmin';
import getEligibleUsers from '@salesforce/apex/ShiftMarketplaceController.getEligibleUsers';
import adminAssignShift from '@salesforce/apex/ShiftMarketplaceController.adminAssignShift';
import adminUnassignShift from '@salesforce/apex/ShiftMarketplaceController.adminUnassignShift';
import checkOverlapsForUsers from '@salesforce/apex/ShiftMarketplaceController.checkOverlapsForUsers';

export default class ShiftMarketplace extends LightningElement {
    @track sessions = [];
    @track filteredSessions = [];
    @track myShiftIds = new Set();
    @track expandedSessionId = null;
    @track isLoading = false;

    // Admin
    isAdmin = false;
    eligibleUsers = [];
    overlapsByShift = {};
    @track showCreateUserModal = false;
    wiredEligibleUsersResult;

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
        { label: 'Zero Staff', value: 'zeroStaff' },
        { label: 'Needs Staff', value: 'needsStaff' },
        { label: 'Fully Staffed', value: 'full' }
    ];

    wiredSessionsResult;
    wiredMyShiftsResult;

    @wire(isCurrentUserAdmin)
    wiredIsAdmin({ data }) {
        if (data !== undefined) {
            this.isAdmin = data;
        }
    }

    @wire(getEligibleUsers)
    wiredEligibleUsers(result) {
        this.wiredEligibleUsersResult = result;
        if (result.data) {
            this.eligibleUsers = result.data;
        }
    }

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
                    staffingLabel: this.buildStaffingLabel(session),
                    shifts: session.shifts.map(shift => ({
                        ...shift,
                        isMyShift: shift.assignedUserName && this.myShiftIds.has(shift.id),
                        statusIcon: shift.isClaimed ? 'utility:check' : 'utility:dash',
                        statusVariant: shift.isClaimed ? 'success' : '',
                        userOptions: this.buildUserOptions(shift.id)
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

    buildUserOptions(shiftId) {
        const overlappingUserIds = this.overlapsByShift[shiftId] || [];
        const options = [{ label: '-- Unassigned --', value: '' }];
        this.eligibleUsers.forEach(u => {
            const hasOverlap = overlappingUserIds.includes(u.value);
            options.push({
                label: hasOverlap ? `⚠ ${u.label}` : u.label,
                value: u.value
            });
        });
        return options;
    }

    rebuildUserOptionsForSessions() {
        this.sessions = this.sessions.map(session => ({
            ...session,
            shifts: session.shifts.map(shift => ({
                ...shift,
                userOptions: this.buildUserOptions(shift.id)
            }))
        }));
        this.applyFilters();
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

    buildStaffingLabel(session) {
        const claimed = session.claimedShifts || 0;
        const total = session.totalShifts || 0;
        const min = session.minShifts || 1;
        const max = session.maxShifts || total;
        const minIcon = session.needsStaff ? '⚠️' : '✅';
        const maxIcon = session.isFull ? ' 🔒' : '';
        return `${claimed} / ${total} shifted — min. staff per fascia: ${min} ${minIcon}  |  max. per fascia: ${max}${maxIcon}`;
    }

    getStatusClass(session) {
        const expanded = session.id === this.expandedSessionId ? ' is-expanded' : '';
        if (session.needsStaff && session.claimedShifts === 0) return 'session-card status-zero-staff' + expanded;
        if (session.needsStaff) return 'session-card status-needs-staff' + expanded;
        return 'session-card status-full' + expanded;
    }

    getStatusKey(session) {
        if (session.needsStaff && session.claimedShifts === 0) return 'zeroStaff';
        if (session.needsStaff) return 'needsStaff';
        return 'full';
    }

    rebuildLocationOptions() {
        const locationSet = new Set();
        this.sessions.forEach(session => {
            if (session.location && (!this.selectedSessionType || session.sessionType === this.selectedSessionType)) {
                locationSet.add(session.location);
            }
        });
        this.locationOptions = [{ label: 'All Locations', value: '' }];
        [...locationSet].sort().forEach(l => {
            this.locationOptions.push({ label: l, value: l });
        });
        if (this.selectedLocation && !locationSet.has(this.selectedLocation)) {
            this.selectedLocation = '';
        }
    }

    // Filter handlers
    handleSessionTypeChange(event) {
        this.selectedSessionType = event.detail.value;
        this.rebuildLocationOptions();
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
        const wasExpanded = this.expandedSessionId === sessionId;
        this.expandedSessionId = wasExpanded ? null : sessionId;
        this.sessions = this.sessions.map(s => ({
            ...s,
            isExpanded: s.id === this.expandedSessionId,
            expandIcon: s.id === this.expandedSessionId ? 'utility:chevronup' : 'utility:chevrondown'
        }));
        this.applyFilters();

        if (!wasExpanded && this.isAdmin) {
            this.loadOverlapsForSession(sessionId);
        }
    }

    async loadOverlapsForSession(sessionId) {
        const session = this.sessions.find(s => s.id === sessionId);
        if (!session) return;

        const shiftIds = session.shifts.map(s => s.id);
        if (shiftIds.length === 0) return;

        try {
            const overlaps = await checkOverlapsForUsers({ shiftIds });
            this.overlapsByShift = { ...this.overlapsByShift, ...overlaps };
            this.rebuildUserOptionsForSessions();
        } catch (error) {
            // Silently fail — overlap indicators are a nice-to-have
        }
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

    async handleAdminAssign(event) {
        event.stopPropagation();
        const shiftId = event.target.dataset.shiftId;
        const userId = event.detail.value;
        const previousUserId = event.target.dataset.currentUser || '';

        if (userId === previousUserId) return;

        if (!userId) {
            await this.doAdminUnassign(shiftId);
            return;
        }

        const overlappingUserIds = this.overlapsByShift[shiftId] || [];
        if (overlappingUserIds.includes(userId)) {
            const userName = this.eligibleUsers.find(u => u.value === userId)?.label || 'This user';
            const proceed = confirm(`Warning: ${userName} has an overlapping shift.\n\nAssign anyway?`);
            if (!proceed) {
                this.resetCombobox(shiftId, previousUserId);
                return;
            }
        }

        this.isLoading = true;
        try {
            await adminAssignShift({ shiftId, userId });
            this.showToast('Success', 'Shift assigned successfully', 'success');
            await this.refreshAll();
            if (this.expandedSessionId) {
                await this.loadOverlapsForSession(this.expandedSessionId);
            }
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error assigning shift', 'error');
            this.resetCombobox(shiftId, previousUserId);
        } finally {
            this.isLoading = false;
        }
    }

    async handleAdminUnassign(event) {
        event.stopPropagation();
        const shiftId = event.target.dataset.shiftId;
        await this.doAdminUnassign(shiftId);
    }

    async doAdminUnassign(shiftId) {
        this.isLoading = true;
        try {
            await adminUnassignShift({ shiftId });
            this.showToast('Success', 'User removed from shift', 'success');
            await this.refreshAll();
            if (this.expandedSessionId) {
                await this.loadOverlapsForSession(this.expandedSessionId);
            }
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error removing user', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    resetCombobox(shiftId, previousValue) {
        const combobox = this.template.querySelector(`lightning-combobox[data-shift-id="${shiftId}"]`);
        if (combobox) {
            combobox.value = previousValue || '';
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

    handleOpenCreateUser() {
        this.showCreateUserModal = true;
    }

    handleCreateUserCancel() {
        this.showCreateUserModal = false;
    }

    async handleUserCreated() {
        this.showCreateUserModal = false;
        await refreshApex(this.wiredEligibleUsersResult);
    }
}
