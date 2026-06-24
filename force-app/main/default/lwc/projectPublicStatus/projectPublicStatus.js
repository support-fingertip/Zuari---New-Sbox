import { LightningElement, api, track } from 'lwc';
import ZUARI_LOGO from '@salesforce/resourceUrl/Zuari';
import getProject from '@salesforce/apex/PublicProjectStatusController.getProject';
import getBlocks from '@salesforce/apex/PublicProjectStatusController.getBlocks';
import getPaymentPlans from '@salesforce/apex/PublicProjectStatusController.getPaymentPlans';
import getMasterPaymentSchedule from '@salesforce/apex/PublicProjectStatusController.getMasterPaymentSchedule';

const STAGE_BLOCK = 'block';
const STAGE_PLAN = 'plan';
const STAGE_MPS = 'mps';

export default class ProjectPublicStatus extends LightningElement {
    @api projectId;

    logoUrl = ZUARI_LOGO;

    @track stage = STAGE_BLOCK;
    @track projectName = '';
    @track blocks = [];
    @track paymentPlans = [];
    @track mpsList = [];
    @track selectedBlockName = '';
    @track selectedPlanName = '';
    @track errorMessage = '';
    @track loading = false;

    connectedCallback() {
        if (!this.projectId) {
            this.errorMessage = 'No project specified in URL.';
            return;
        }
        this.loadProjectAndBlocks();
    }

    get showBlocks() { return this.stage === STAGE_BLOCK; }
    get showPlans() { return this.stage === STAGE_PLAN; }
    get showMps() { return this.stage === STAGE_MPS; }
    get hasError() { return !!this.errorMessage; }
    get hasBlocks() { return this.blocks && this.blocks.length > 0; }
    get hasPlans() { return this.paymentPlans && this.paymentPlans.length > 0; }
    get hasMps() { return this.mpsList && this.mpsList.length > 0; }

    loadProjectAndBlocks() {
        this.loading = true;
        Promise.all([
            getProject({ projectId: this.projectId }),
            getBlocks({ projectId: this.projectId })
        ])
            .then(([project, blocks]) => {
                if (!project) {
                    this.errorMessage = 'No project found for this link.';
                    return;
                }
                this.projectName = project.Name;
                this.blocks = blocks || [];
            })
            .catch(err => {
                this.errorMessage = this.readError(err);
            })
            .finally(() => {
                this.loading = false;
            });
    }

    handleBlockClick(event) {
        const blockId = event.currentTarget.dataset.id;
        const blockName = event.currentTarget.dataset.name;
        this.selectedBlockName = blockName;
        this.loading = true;
        getPaymentPlans({ blockId })
            .then(plans => {
                this.paymentPlans = plans || [];
                this.stage = STAGE_PLAN;
            })
            .catch(err => {
                this.errorMessage = this.readError(err);
            })
            .finally(() => {
                this.loading = false;
            });
    }

    handlePlanClick(event) {
        const paymentPlanId = event.currentTarget.dataset.id;
        const planName = event.currentTarget.dataset.name;
        this.selectedPlanName = planName;
        this.loading = true;
        getMasterPaymentSchedule({ paymentPlanId })
            .then(rows => {
                this.mpsList = rows || [];
                this.stage = STAGE_MPS;
            })
            .catch(err => {
                this.errorMessage = this.readError(err);
            })
            .finally(() => {
                this.loading = false;
            });
    }

    handleBackToBlocks() {
        this.stage = STAGE_BLOCK;
        this.paymentPlans = [];
        this.selectedBlockName = '';
    }

    handleBackToPlans() {
        this.stage = STAGE_PLAN;
        this.mpsList = [];
        this.selectedPlanName = '';
    }

    readError(err) {
        if (!err) return 'Unknown error';
        if (err.body && err.body.message) return err.body.message;
        if (typeof err.message === 'string') return err.message;
        return JSON.stringify(err);
    }
}