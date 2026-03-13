import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRosterByPerson from '@salesforce/apex/AdminRosterController.getRosterByPerson';
import getRosterByShift from '@salesforce/apex/AdminRosterController.getRosterByShift';

export default class AdminMasterRoster extends LightningElement {
    @track activeTab = 'byPerson';
    @track rosterByPerson = null;
    @track rosterByShift = [];
    @track isLoading = false;

    wiredRosterByPersonResult;
    wiredRosterByShiftResult;

    @wire(getRosterByPerson)
    wiredPersonRoster(result) {
        this.wiredRosterByPersonResult = result;
        if (result.data) {
            this.rosterByPerson = result.data;
        } else if (result.error) {
            this.showToast('Error', 'Error loading roster by person', 'error');
        }
    }

    @wire(getRosterByShift)
    wiredShiftRoster(result) {
        this.wiredRosterByShiftResult = result;
        if (result.data) {
            this.rosterByShift = result.data;
        } else if (result.error) {
            this.showToast('Error', 'Error loading roster by shift', 'error');
        }
    }

    handleTabChange(event) {
        this.activeTab = event.target.value;
    }

    handleRefresh() {
        this.isLoading = true;
        Promise.all([
            refreshApex(this.wiredRosterByPersonResult),
            refreshApex(this.wiredRosterByShiftResult)
        ]).finally(() => {
            this.isLoading = false;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get isPersonTabActive() {
        return this.activeTab === 'byPerson';
    }

    get isShiftTabActive() {
        return this.activeTab === 'byShift';
    }

    get hasPersonRoster() {
        return this.rosterByPerson?.rows?.length > 0;
    }

    get hasShiftRoster() {
        return this.rosterByShift.length > 0;
    }

    get timeSlots() {
        return this.rosterByPerson?.timeSlots || [];
    }

    get personRows() {
        const rows = this.rosterByPerson?.rows || [];
        const slots = this.timeSlots;
        return rows.map(row => ({
            ...row,
            slotCells: slots.map(slot => ({
                key: row.userName + '-' + slot,
                slot: slot,
                value: row.cells ? row.cells[slot] : null,
                tooltip: row.tooltips ? row.tooltips[slot] : null,
                hasValue: !!(row.cells && row.cells[slot])
            }))
        }));
    }
}
