import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import MySchedule from 'c/mySchedule';
import getMyShifts from '@salesforce/apex/ShiftMarketplaceController.getMyShifts';
import isCurrentUserAdmin from '@salesforce/apex/ShiftMarketplaceController.isCurrentUserAdmin';
import getEligibleUsers from '@salesforce/apex/ShiftMarketplaceController.getEligibleUsers';

const getMyShiftsAdapter = registerApexTestWireAdapter(getMyShifts);
const isAdminAdapter = registerApexTestWireAdapter(isCurrentUserAdmin);
const getEligibleUsersAdapter = registerApexTestWireAdapter(getEligibleUsers);

describe('c-my-schedule', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('mounts without errors', () => {
        const el = createElement('c-my-schedule', { is: MySchedule });
        expect(() => document.body.appendChild(el)).not.toThrow();
    });

    it('renders when wire returns empty data', () => {
        const el = createElement('c-my-schedule', { is: MySchedule });
        document.body.appendChild(el);
        isAdminAdapter.emit(false);
        getEligibleUsersAdapter.emit([]);
        getMyShiftsAdapter.emit([]);
        return Promise.resolve().then(() => {
            expect(el.shadowRoot).toBeTruthy();
        });
    });
});
