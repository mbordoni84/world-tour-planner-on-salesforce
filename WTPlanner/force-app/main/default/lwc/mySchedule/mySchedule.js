import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getMyShifts from '@salesforce/apex/ShiftMarketplaceController.getMyShifts';
import getShiftsForUser from '@salesforce/apex/ShiftMarketplaceController.getShiftsForUser';
import dropShift from '@salesforce/apex/ShiftMarketplaceController.dropShift';
import isCurrentUserAdmin from '@salesforce/apex/ShiftMarketplaceController.isCurrentUserAdmin';
import getEligibleUsers from '@salesforce/apex/ShiftMarketplaceController.getEligibleUsers';

export default class MySchedule extends NavigationMixin(LightningElement) {
    @track myShifts = [];
    @track isLoading = false;
    @track isAdmin = false;
    @track selectedUserId = '';
    @track userOptions = [];
    wiredMyShiftsResult;

    @wire(isCurrentUserAdmin)
    wiredIsAdmin({ data }) {
        if (data !== undefined) {
            this.isAdmin = data;
        }
    }

    @wire(getEligibleUsers)
    wiredEligibleUsers({ data }) {
        if (data) {
            this.userOptions = [
                { label: '-- My Schedule --', value: '' },
                ...data.map(u => ({ label: u.label, value: u.value }))
            ];
        }
    }

    @wire(getMyShifts)
    wiredShifts(result) {
        this.wiredMyShiftsResult = result;
        if (!this.selectedUserId && result.data) {
            this.myShifts = this.mapShifts(result.data);
        } else if (result.error) {
            this.showToast('Error', 'Error loading your schedule', 'error');
        }
    }

    mapShifts(data) {
        return data.map(shift => ({
            ...shift,
            hasOverlapClass: shift.hasOverlap ? 'has-overlap' : '',
            shiftTime: `${shift.startTime} - ${shift.endTime}`
        }));
    }

    async handleUserChange(event) {
        this.selectedUserId = event.detail.value;
        if (!this.selectedUserId) {
            this.myShifts = this.wiredMyShiftsResult?.data
                ? this.mapShifts(this.wiredMyShiftsResult.data)
                : [];
            return;
        }
        this.isLoading = true;
        try {
            const data = await getShiftsForUser({ userId: this.selectedUserId });
            this.myShifts = this.mapShifts(data);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error loading schedule', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleDropShift(event) {
        const shiftId = event.target.dataset.id;
        const shiftName = event.target.dataset.name;

        const confirmed = confirm(`Are you sure you want to drop ${shiftName}?`);
        if (!confirmed) return;

        this.isLoading = true;

        try {
            await dropShift({ shiftId });
            this.showToast('Success', 'Shift dropped successfully', 'success');
            if (this.selectedUserId) {
                const data = await getShiftsForUser({ userId: this.selectedUserId });
                this.myShifts = this.mapShifts(data);
            } else {
                await refreshApex(this.wiredMyShiftsResult);
            }
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error dropping shift', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleViewOverlaps() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Overlap_Dashboard'
            }
        });
    }

    async handleRefresh() {
        this.isLoading = true;
        try {
            if (this.selectedUserId) {
                const data = await getShiftsForUser({ userId: this.selectedUserId });
                this.myShifts = this.mapShifts(data);
            } else {
                await refreshApex(this.wiredMyShiftsResult);
            }
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get hasShifts() {
        return this.myShifts.length > 0;
    }

    get hasOverlaps() {
        return this.myShifts.some(s => s.hasOverlap);
    }

    get overlapCount() {
        return this.myShifts.filter(s => s.hasOverlap).length;
    }

    get scheduleTitle() {
        if (!this.selectedUserId) return 'My Schedule';
        const user = this.userOptions.find(u => u.value === this.selectedUserId);
        return user ? `Schedule: ${user.label}` : 'Schedule';
    }

    get isViewingOtherUser() {
        return !!this.selectedUserId;
    }
}
