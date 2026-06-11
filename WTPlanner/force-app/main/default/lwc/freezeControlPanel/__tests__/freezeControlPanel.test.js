import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import FreezeControlPanel from 'c/freezeControlPanel';
import getSessionTypesWithSessions from '@salesforce/apex/FreezeControlController.getSessionTypesWithSessions';

const getSessionTypesAdapter = registerApexTestWireAdapter(getSessionTypesWithSessions);

describe('c-freeze-control-panel', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('mounts without errors', () => {
        const el = createElement('c-freeze-control-panel', { is: FreezeControlPanel });
        expect(() => document.body.appendChild(el)).not.toThrow();
    });

    it('renders with empty session types', () => {
        const el = createElement('c-freeze-control-panel', { is: FreezeControlPanel });
        document.body.appendChild(el);
        getSessionTypesAdapter.emit([]);
        return Promise.resolve().then(() => {
            expect(el.shadowRoot).toBeTruthy();
        });
    });
});
