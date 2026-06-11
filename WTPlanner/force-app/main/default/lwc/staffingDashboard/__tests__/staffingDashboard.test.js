import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import StaffingDashboard from 'c/staffingDashboard';
import getDashboardData from '@salesforce/apex/StaffingDashboardController.getDashboardData';

const getDashboardDataAdapter = registerApexTestWireAdapter(getDashboardData);

const MOCK_DASHBOARD = {
    totalShifts: 10,
    assignedCount: 6,
    unassignedCount: 4,
    fillRate: 60.0,
    sessionList: [],
    sessionTypeKpiList: [],
    leaderboard: []
};

describe('c-staffing-dashboard', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('mounts without errors when wire returns data', () => {
        const el = createElement('c-staffing-dashboard', { is: StaffingDashboard });
        document.body.appendChild(el);
        getDashboardDataAdapter.emit(MOCK_DASHBOARD);
        return Promise.resolve().then(() => {
            expect(el.shadowRoot).toBeTruthy();
        });
    });

    it('renders with empty data', () => {
        const el = createElement('c-staffing-dashboard', { is: StaffingDashboard });
        document.body.appendChild(el);
        getDashboardDataAdapter.emit({
            totalShifts: 0, assignedCount: 0, unassignedCount: 0,
            fillRate: 0, sessionList: [], sessionTypeKpiList: [], leaderboard: []
        });
        return Promise.resolve().then(() => {
            expect(el.shadowRoot).toBeTruthy();
        });
    });
});
