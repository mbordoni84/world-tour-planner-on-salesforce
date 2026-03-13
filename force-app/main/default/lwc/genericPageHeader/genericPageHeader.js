import { LightningElement, api } from 'lwc';

export default class GenericPageHeader extends LightningElement {
    @api title = '';
    @api subtitle = '';
    @api iconName = '';
    @api showRefreshButton = false;
    @api isLoading = false;

    /**
     * Handle refresh button click
     * Dispatches a custom 'refresh' event that parent components can listen to
     */
    handleRefresh() {
        const refreshEvent = new CustomEvent('refresh', {
            detail: {
                message: 'Refresh requested from header'
            }
        });
        this.dispatchEvent(refreshEvent);
    }
}
