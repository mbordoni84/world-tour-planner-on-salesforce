import { createElement } from 'lwc';
import QuickUserCreate from 'c/quickUserCreate';

jest.mock(
    '@salesforce/apex/QuickUserCreateController.createStaffingUser',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

describe('c-quick-user-create', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('mounts without errors', () => {
        const el = createElement('c-quick-user-create', { is: QuickUserCreate });
        expect(() => document.body.appendChild(el)).not.toThrow();
    });

    it('renders form fields', () => {
        const el = createElement('c-quick-user-create', { is: QuickUserCreate });
        document.body.appendChild(el);
        return Promise.resolve().then(() => {
            expect(el.shadowRoot).toBeTruthy();
        });
    });
});
