import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createStaffingUser from '@salesforce/apex/QuickUserCreateController.createStaffingUser';

export default class QuickUserCreate extends LightningElement {
    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track isCreating = false;

    handleFirstNameChange(event) {
        this.firstName = event.target.value;
    }

    handleLastNameChange(event) {
        this.lastName = event.target.value;
    }

    handleEmailChange(event) {
        this.email = event.target.value;
    }

    get hasPreview() {
        return this.firstName && this.lastName;
    }

    get generatedUsername() {
        if (!this.firstName || !this.lastName) return '';
        const first = this.firstName.toLowerCase().replace(/[^a-z]/g, '');
        const last = this.lastName.toLowerCase().replace(/[^a-z]/g, '');
        return `${first}.${last}@staffingapp.[orgId].sfdc`;
    }

    get generatedAlias() {
        if (!this.firstName || !this.lastName) return '';
        return (this.firstName.substring(0, 7) + this.lastName.substring(0, 1)).substring(0, 8);
    }

    validateForm() {
        const inputs = this.template.querySelectorAll('lightning-input');
        let valid = true;
        inputs.forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
                valid = false;
            }
        });
        return valid;
    }

    async handleCreate() {
        if (!this.validateForm()) return;

        this.isCreating = true;
        try {
            const result = await createStaffingUser({
                firstName: this.firstName.trim(),
                lastName: this.lastName.trim(),
                email: this.email.trim()
            });

            this.dispatchEvent(new ShowToastEvent({
                title: 'User Created',
                message: `${result.name} created (${result.username})`,
                variant: 'success'
            }));

            this.dispatchEvent(new CustomEvent('usercreated', {
                detail: { userId: result.userId, name: result.name }
            }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'Error creating user',
                variant: 'error'
            }));
        } finally {
            this.isCreating = false;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}
