import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import AdminMasterRoster from 'c/adminMasterRoster';
import getRosterData from '@salesforce/apex/AdminRosterController.getRosterData';

const getRosterDataAdapter = registerApexTestWireAdapter(getRosterData);

describe('c-admin-master-roster', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('mounts without errors', () => {
        const el = createElement('c-admin-master-roster', { is: AdminMasterRoster });
        expect(() => document.body.appendChild(el)).not.toThrow();
    });

    it('renders when wire returns empty data', () => {
        const el = createElement('c-admin-master-roster', { is: AdminMasterRoster });
        document.body.appendChild(el);
        getRosterDataAdapter.emit({ users: [], timeSlots: [], matrix: [] });
        return Promise.resolve().then(() => {
            expect(el.shadowRoot).toBeTruthy();
        });
    });
});
