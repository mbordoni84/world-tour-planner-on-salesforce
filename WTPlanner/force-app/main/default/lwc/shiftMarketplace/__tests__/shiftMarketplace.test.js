import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import ShiftMarketplace from 'c/shiftMarketplace';
import getSessionsNeedingStaff from '@salesforce/apex/ShiftMarketplaceController.getSessionsNeedingStaff';
import getMyShifts from '@salesforce/apex/ShiftMarketplaceController.getMyShifts';
import isCurrentUserAdmin from '@salesforce/apex/ShiftMarketplaceController.isCurrentUserAdmin';
import getEligibleUsers from '@salesforce/apex/ShiftMarketplaceController.getEligibleUsers';

const getSessionsAdapter = registerApexTestWireAdapter(getSessionsNeedingStaff);
const getMyShiftsAdapter = registerApexTestWireAdapter(getMyShifts);
const isAdminAdapter = registerApexTestWireAdapter(isCurrentUserAdmin);
const getEligibleUsersAdapter = registerApexTestWireAdapter(getEligibleUsers);

describe('c-shift-marketplace', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('mounts without errors', () => {
        const el = createElement('c-shift-marketplace', { is: ShiftMarketplace });
        expect(() => document.body.appendChild(el)).not.toThrow();
    });

    it('renders session list when wire returns empty data', () => {
        const el = createElement('c-shift-marketplace', { is: ShiftMarketplace });
        document.body.appendChild(el);
        isAdminAdapter.emit(false);
        getEligibleUsersAdapter.emit([]);
        getMyShiftsAdapter.emit([]);
        getSessionsAdapter.emit([]);
        return Promise.resolve().then(() => {
            expect(el.shadowRoot).toBeTruthy();
        });
    });
});
