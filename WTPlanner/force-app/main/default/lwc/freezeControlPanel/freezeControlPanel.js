import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSessionTypesWithSessions from '@salesforce/apex/FreezeControlController.getSessionTypesWithSessions';
import toggleSessionTypeFreeze from '@salesforce/apex/FreezeControlController.toggleSessionTypeFreeze';
import toggleSessionFreeze from '@salesforce/apex/FreezeControlController.toggleSessionFreeze';
import bulkFreezeSessionsForType from '@salesforce/apex/FreezeControlController.bulkFreezeSessionsForType';

export default class FreezeControlPanel extends LightningElement {
    @track sessionTypes = [];
    @track expandedTypes = new Set();
    @track isLoading = false;
    wiredResult;

    @wire(getSessionTypesWithSessions)
    wiredData(result) {
        this.wiredResult = result;
        if (result.data) {
            this.sessionTypes = result.data.map(st => ({
                ...st,
                isExpanded: this.expandedTypes.has(st.id),
                expandIcon: this.expandedTypes.has(st.id) ? 'utility:chevrondown' : 'utility:chevronright',
                sessionCount: st.sessions.length,
                frozenSessionCount: st.sessions.filter(s => s.isFrozen).length,
                sessions: st.sessions.map(s => ({
                    ...s,
                    effectivelyFrozen: s.isFrozen || st.isFrozen,
                    inheritedFreeze: !s.isFrozen && st.isFrozen
                }))
            }));
        } else if (result.error) {
            this.showToast('Error', 'Error loading session types', 'error');
        }
    }

    handleToggleExpand(event) {
        const typeId = event.currentTarget.dataset.id;
        if (this.expandedTypes.has(typeId)) {
            this.expandedTypes.delete(typeId);
        } else {
            this.expandedTypes.add(typeId);
        }
        this.sessionTypes = this.sessionTypes.map(st => ({
            ...st,
            isExpanded: this.expandedTypes.has(st.id),
            expandIcon: this.expandedTypes.has(st.id) ? 'utility:chevrondown' : 'utility:chevronright'
        }));
    }

    async handleTypeToggle(event) {
        const typeId = event.target.dataset.id;
        const isFrozen = event.target.checked;
        this.isLoading = true;
        try {
            await toggleSessionTypeFreeze({ sessionTypeId: typeId, isFrozen });
            await refreshApex(this.wiredResult);
            this.showToast('Success', `Session type ${isFrozen ? 'frozen' : 'unfrozen'}`, 'success');
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error toggling freeze', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleSessionToggle(event) {
        const sessionId = event.target.dataset.id;
        const isFrozen = event.target.checked;
        this.isLoading = true;
        try {
            await toggleSessionFreeze({ sessionId, isFrozen });
            await refreshApex(this.wiredResult);
            this.showToast('Success', `Session ${isFrozen ? 'frozen' : 'unfrozen'}`, 'success');
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error toggling freeze', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleBulkFreeze(event) {
        const typeId = event.target.dataset.id;
        this.isLoading = true;
        try {
            await bulkFreezeSessionsForType({ sessionTypeId: typeId, isFrozen: true });
            await refreshApex(this.wiredResult);
            this.showToast('Success', 'All sessions frozen', 'success');
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error freezing sessions', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleBulkUnfreeze(event) {
        const typeId = event.target.dataset.id;
        this.isLoading = true;
        try {
            await bulkFreezeSessionsForType({ sessionTypeId: typeId, isFrozen: false });
            await refreshApex(this.wiredResult);
            this.showToast('Success', 'All sessions unfrozen', 'success');
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error unfreezing sessions', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleRefresh() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredResult);
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get hasSessionTypes() {
        return this.sessionTypes.length > 0;
    }
}
