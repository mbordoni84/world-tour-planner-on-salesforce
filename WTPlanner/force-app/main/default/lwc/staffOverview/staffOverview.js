import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isCurrentUserAdmin from '@salesforce/apex/ShiftMarketplaceController.isCurrentUserAdmin';
import getStaffOverview from '@salesforce/apex/StaffingDashboardController.getStaffOverview';

export default class StaffOverview extends LightningElement {
    @track isAdmin = false;
    @track isLoading = false;
    @track filteredMembers = [];

    @track maxHoursFilter = '';
    @track maxShiftsFilter = '';
    @track ownerFilter = 'all';
    @track sortField = 'name';
    @track sortAsc = true;
    @track copyAllLabel = 'Copy';
    @track copyOwnersLabel = 'Copy';

    _members = [];
    totalStaffedVal = 0;
    avgHoursVal = 0;
    emailListVal = '';
    ownerEmailListVal = '';

    ownerFilterOptions = [
        { label: 'Tutti', value: 'all' },
        { label: 'Solo owner', value: 'owners' },
        { label: 'Solo non-owner', value: 'nonowners' }
    ];

    @wire(isCurrentUserAdmin)
    wiredIsAdmin({ data }) {
        if (data !== undefined) {
            this.isAdmin = data;
            if (data) this.loadData();
        }
    }

    async loadData() {
        this.isLoading = true;
        try {
            const result = await getStaffOverview();
            this.totalStaffedVal = result.totalStaffed;
            this.avgHoursVal = result.avgHours;
            this.emailListVal = result.emailList;
            this.ownerEmailListVal = result.ownerEmailList;
            this._members = result.members.map(m => ({
                ...m,
                totalHours: parseFloat(m.totalHours),
                shiftCount: parseInt(m.shiftCount, 10),
                ownerSessionCount: parseInt(m.ownerSessionCount, 10),
                rowClass: m.isUnderFourHours ? 'under-threshold' : ''
            }));
            this.maxHoursFilter = '';
            this.maxShiftsFilter = '';
            this.ownerFilter = 'all';
            this.sortField = 'name';
            this.sortAsc = true;
            this.applyFilters();
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: e.body?.message || 'Error loading staff overview',
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }

    applyFilters() {
        let result = [...this._members];
        const maxH = parseFloat(this.maxHoursFilter);
        const maxS = parseInt(this.maxShiftsFilter, 10);
        if (this.maxHoursFilter !== '' && !isNaN(maxH)) result = result.filter(m => m.totalHours <= maxH);
        if (this.maxShiftsFilter !== '' && !isNaN(maxS)) result = result.filter(m => m.shiftCount <= maxS);
        if (this.ownerFilter === 'owners')    result = result.filter(m => m.ownerSessionCount > 0);
        if (this.ownerFilter === 'nonowners') result = result.filter(m => m.ownerSessionCount === 0);
        const field = this.sortField;
        const asc = this.sortAsc ? 1 : -1;
        result.sort((a, b) => {
            if (a[field] < b[field]) return -1 * asc;
            if (a[field] > b[field]) return 1 * asc;
            return 0;
        });
        this.filteredMembers = result;
    }

    handleRefresh() { this.loadData(); }
    handleTextareaClick(event) { event.target.select(); }

    handleHoursChange(event) {
        this.maxHoursFilter = event.detail.value;
        this.applyFilters();
    }
    handleShiftsChange(event) {
        this.maxShiftsFilter = event.detail.value;
        this.applyFilters();
    }
    handleOwnerFilterChange(event) {
        this.ownerFilter = event.detail.value;
        this.applyFilters();
    }
    handleResetFilters() {
        this.maxHoursFilter = '';
        this.maxShiftsFilter = '';
        this.ownerFilter = 'all';
        this.applyFilters();
    }
    handleSort(event) {
        const field = event.currentTarget.dataset.field;
        if (this.sortField === field) {
            this.sortAsc = !this.sortAsc;
        } else {
            this.sortField = field;
            this.sortAsc = field === 'name';
        }
        this.applyFilters();
    }

    async handleCopy(event) {
        const key = event.currentTarget.dataset.key;
        const text = key === 'owners' ? this.ownerEmailListVal : this.emailListVal;
        try {
            await navigator.clipboard.writeText(text);
            if (key === 'owners') {
                this.copyOwnersLabel = '✓ Copied!';
                setTimeout(() => { this.copyOwnersLabel = 'Copy'; }, 2500);
            } else {
                this.copyAllLabel = '✓ Copied!';
                setTimeout(() => { this.copyAllLabel = 'Copy'; }, 2500);
            }
        } catch (e) {
            const ta = this.template.querySelector(`textarea[data-key="${key}"]`);
            if (ta) ta.select();
            this.dispatchEvent(new ShowToastEvent({
                title: 'Select & press Ctrl+C / Cmd+C',
                message: 'Clipboard API not available',
                variant: 'info'
            }));
        }
    }

    get totalStaffed() { return this.totalStaffedVal; }
    get avgHours() { return this.avgHoursVal; }
    get emailList() { return this.emailListVal; }
    get ownerEmailList() { return this.ownerEmailListVal; }
    get hasData() { return this._members.length > 0; }
    get filteredCount() { return this.filteredMembers.length; }

    sortIcon(field) {
        if (this.sortField !== field) return '↕';
        return this.sortAsc ? '↑' : '↓';
    }
    get sortIconName()   { return this.sortIcon('name'); }
    get sortIconHours()  { return this.sortIcon('totalHours'); }
    get sortIconShifts() { return this.sortIcon('shiftCount'); }
    get sortIconOwner()  { return this.sortIcon('ownerSessionCount'); }
}
