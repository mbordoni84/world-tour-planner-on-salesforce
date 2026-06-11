import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import StaffOverview from 'c/staffOverview';
import isCurrentUserAdmin from '@salesforce/apex/ShiftMarketplaceController.isCurrentUserAdmin';
import getStaffOverview from '@salesforce/apex/StaffingDashboardController.getStaffOverview';

const isAdminAdapter = registerApexTestWireAdapter(isCurrentUserAdmin);
const getStaffOverviewAdapter = registerApexTestWireAdapter(getStaffOverview);

describe('c-staff-overview', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('mounts without errors', () => {
        const el = createElement('c-staff-overview', { is: StaffOverview });
        expect(() => document.body.appendChild(el)).not.toThrow();
    });

    it('renders when wire returns empty data', () => {
        const el = createElement('c-staff-overview', { is: StaffOverview });
        document.body.appendChild(el);
        isAdminAdapter.emit(true);
        getStaffOverviewAdapter.emit([]);
        return Promise.resolve().then(() => {
            expect(el.shadowRoot).toBeTruthy();
        });
    });
});
