import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOverlappingShifts from '@salesforce/apex/OverlapDashboardController.getOverlappingShifts';
import dropShift from '@salesforce/apex/OverlapDashboardController.dropShift';

export default class OverlapDashboard extends LightningElement {
    @track allOverlaps = [];
    @track filteredOverlaps = [];
    @track isLoading = false;
    wiredOverlapsResult;

    // Filters
    @track filterUser = '';
    @track filterSessionType = '';
    @track filterSession = '';

    // Filter options (built from data)
    @track sessionTypeOptions = [{ label: 'All Types', value: '' }];
    @track sessionOptions = [{ label: 'All Sessions', value: '' }];

    columns = [
        { label: 'User', fieldName: 'userName', type: 'text' },
        {
            label: 'Shift 1',
            fieldName: 'shift1Session',
            type: 'text',
            cellAttributes: { class: 'slds-text-title_bold' }
        },
        { label: 'Time 1', fieldName: 'shift1Time', type: 'text' },
        {
            label: 'Shift 2',
            fieldName: 'shift2Session',
            type: 'text',
            cellAttributes: { class: 'slds-text-title_bold' }
        },
        { label: 'Time 2', fieldName: 'shift2Time', type: 'text' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Drop Shift 1', name: 'drop_shift_1' },
                    { label: 'Drop Shift 2', name: 'drop_shift_2' }
                ]
            }
        }
    ];

    @wire(getOverlappingShifts)
    wiredOverlaps(result) {
        this.wiredOverlapsResult = result;
        if (result.data) {
            const typeSet = new Set();
            const sessionSet = new Set();

            this.allOverlaps = result.data.map(overlap => {
                if (overlap.shift1SessionType) typeSet.add(overlap.shift1SessionType);
                if (overlap.shift2SessionType) typeSet.add(overlap.shift2SessionType);
                if (overlap.shift1Session) sessionSet.add(overlap.shift1Session);
                if (overlap.shift2Session) sessionSet.add(overlap.shift2Session);

                return {
                    ...overlap,
                    id: `${overlap.shift1Id}-${overlap.shift2Id}`
                };
            });

            this.sessionTypeOptions = [{ label: 'All Types', value: '' }];
            [...typeSet].sort().forEach(t => {
                this.sessionTypeOptions.push({ label: t, value: t });
            });

            this.sessionOptions = [{ label: 'All Sessions', value: '' }];
            [...sessionSet].sort().forEach(s => {
                this.sessionOptions.push({ label: s, value: s });
            });

            this.applyFilters();
        } else if (result.error) {
            this.showToast('Error', 'Error loading overlaps', 'error');
        }
    }

    // Filter handlers
    handleFilterUser(event) {
        this.filterUser = event.target.value;
        this.applyFilters();
    }

    handleFilterSessionType(event) {
        this.filterSessionType = event.detail.value;
        this.applyFilters();
    }

    handleFilterSession(event) {
        this.filterSession = event.detail.value;
        this.applyFilters();
    }

    handleClearFilters() {
        this.filterUser = '';
        this.filterSessionType = '';
        this.filterSession = '';
        this.applyFilters();
    }

    applyFilters() {
        const userSearch = this.filterUser ? this.filterUser.toLowerCase() : '';

        this.filteredOverlaps = this.allOverlaps.filter(o => {
            if (userSearch && !o.userName.toLowerCase().includes(userSearch)) return false;

            if (this.filterSessionType) {
                const matches = o.shift1SessionType === this.filterSessionType ||
                    o.shift2SessionType === this.filterSessionType;
                if (!matches) return false;
            }

            if (this.filterSession) {
                const matches = o.shift1Session === this.filterSession ||
                    o.shift2Session === this.filterSession;
                if (!matches) return false;
            }

            return true;
        });
    }

    async handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        let shiftId = null;
        let shiftName = '';

        if (action.name === 'drop_shift_1') {
            shiftId = row.shift1Id;
            shiftName = row.shift1Session;
        } else if (action.name === 'drop_shift_2') {
            shiftId = row.shift2Id;
            shiftName = row.shift2Session;
        }

        if (!shiftId) return;

        const confirmed = confirm(`Are you sure you want to drop ${shiftName}?`);
        if (!confirmed) return;

        this.isLoading = true;

        try {
            await dropShift({ shiftId });
            this.showToast('Success', 'Shift dropped successfully', 'success');
            await refreshApex(this.wiredOverlapsResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error dropping shift', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredOverlapsResult).finally(() => {
            this.isLoading = false;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get hasOverlaps() {
        return this.filteredOverlaps.length > 0;
    }

    get overlapCount() {
        return this.filteredOverlaps.length;
    }

    get totalOverlapCount() {
        return this.allOverlaps.length;
    }

    get hasActiveFilters() {
        return !!(this.filterUser || this.filterSessionType || this.filterSession);
    }
}
