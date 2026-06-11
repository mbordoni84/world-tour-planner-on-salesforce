import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import OverlapDashboard from 'c/overlapDashboard';
import getOverlappingShifts from '@salesforce/apex/OverlapDashboardController.getOverlappingShifts';

const getOverlappingShiftsAdapter = registerApexTestWireAdapter(getOverlappingShifts);

describe('c-overlap-dashboard', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('mounts without errors', () => {
        const el = createElement('c-overlap-dashboard', { is: OverlapDashboard });
        expect(() => document.body.appendChild(el)).not.toThrow();
    });

    it('renders with empty overlaps list', () => {
        const el = createElement('c-overlap-dashboard', { is: OverlapDashboard });
        document.body.appendChild(el);
        getOverlappingShiftsAdapter.emit([]);
        return Promise.resolve().then(() => {
            expect(el.shadowRoot).toBeTruthy();
        });
    });
});
