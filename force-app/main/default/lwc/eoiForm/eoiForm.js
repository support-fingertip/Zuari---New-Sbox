import { LightningElement, track } from 'lwc';
import getFormMetadata from '@salesforce/apex/EOIFormController.getFormMetadata';
import searchChannelPartners from '@salesforce/apex/EOIFormController.searchChannelPartners';
import submitEOI from '@salesforce/apex/EOIFormController.submitEOI';

const MAX_FILE = 3 * 1024 * 1024;

// Toggle all console logging on/off here.
const DEBUG = true;
function log(...args) { if (DEBUG) { console.log('EOI DEBUG →', ...args); } }

const PATTERNS = {
    pan:     { re: /^[A-Z]{5}[0-9]{4}[A-Z]$/, norm: v => v.toUpperCase().replace(/[^A-Z0-9]/g, '') },
    aadhaar: { re: /^[0-9]{12}$/,             norm: v => v.replace(/\D/g, '') },
    phone:   { re: /^[6-9][0-9]{9}$/,         norm: v => v.replace(/\D/g, '') },
    pin:     { re: /^[0-9]{6}$/,              norm: v => v.replace(/\D/g, '') }
};

const INDIAN_STATES = ['Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh','Goa','Gujarat','Haryana','Himachal Pradesh','Jharkhand','Karnataka','Kerala','Madhya Pradesh','Maharashtra','Manipur','Meghalaya','Mizoram','Nagaland','Odisha','Punjab','Rajasthan','Sikkim','Tamil Nadu','Telangana','Tripura','Uttar Pradesh','Uttarakhand','West Bengal','Andaman and Nicobar Islands','Chandigarh','Dadra and Nagar Haveli and Daman and Diu','Delhi','Jammu and Kashmir','Ladakh','Lakshadweep','Puducherry'];

export default class EoiForm extends LightningElement {
    @track meta = {};
    states = INDIAN_STATES;

    @track secondarySourceOptions = [];
    sourceMap = {};

    @track cpResults = [];
    showCpResults = false;
    _cpTimer;

    showOtherQual = false;
    showOtherPurpose = false;
    showOtherSource = false;

    files = {};                 // { category: {fileName,title,base64} }
    @track filePreviews = [];   // [{category,name,imgUrl}]

    showError = false;
    errorMessage = '';

    submitting = false;
    submitted = false;
    refId;
    attachedCount = 0;

    // debug values shown on the thank-you screen
    @track filesReceived = 0;
    @track attachErrorText = '';

    @track dpName = '\u2014';
    @track dpMobile = '\u2014';
    @track dpEmail = '\u2014';
    @track dpAddress = '\u2014';
    dpDate = new Date().toLocaleDateString('en-GB');

    /* ---------------- lifecycle ---------------- */
    connectedCallback() {
        log('connectedCallback - loading metadata');
        getFormMetadata()
            .then(data => {
                this.meta = data || {};
                this.sourceMap = (data && data.sourceMap) ? data.sourceMap : {};
                log('metadata loaded OK');
            })
            .catch(e => {
                log('metadata load FAILED', e);
                this.fail(this.reason(e) || 'Could not load the form. Please refresh.');
            });
    }

    /* ---------------- getters ---------------- */
    get showForm() { return !this.submitted; }
    get submitLabel() { return this.submitting ? 'Submitting...' : 'Submit Expression of Interest'; }
    get cpHasResults() { return this.cpResults && this.cpResults.length > 0; }
    get cpNoResults() { return !this.cpHasResults; }

    /* ---------------- small helpers ---------------- */
    q(sel) { return this.template.querySelector(sel); }
    qa(sel) { return this.template.querySelectorAll(sel); }
    byId(id) { return this.q(`[data-id="${id}"]`); }
    fieldEl(api) { return this.q(`[data-field="${api}"]`); }
    val(id) { const el = this.byId(id); return el ? (el.value || '') : ''; }

    fail(msg) {
        this.errorMessage = msg;
        this.showError = true;
        this.scrollTop();
    }
    clearError() { this.showError = false; this.errorMessage = ''; }
    scrollTop() { try { window.scrollTo({ top: 0, behavior: 'smooth' }); } catch (e) { /* noop */ } }
    reason(e) { return (e && e.body && e.body.message) ? e.body.message : (e && e.message) ? e.message : ''; }

    /* ---------------- "Other ..." toggles ---------------- */
    handleOtherToggle(event) {
        const which = event.target.dataset.other;
        const isOther = (event.target.value || '').toLowerCase().indexOf('other') >= 0;
        if (which === 'qual') this.showOtherQual = isOther;
        else if (which === 'purpose') this.showOtherPurpose = isOther;
        else if (which === 'source') this.showOtherSource = isOther;
    }

    /* ---------------- DPDP live preview ---------------- */
    refreshDpdp() {
        const sal = (this.fieldEl('Salutation__c') || {}).value || '';
        const nm = (this.fieldEl('Name__c') || {}).value || '';
        const full = (sal ? sal + ' ' : '') + nm;
        this.dpName = nm ? full : '\u2014';
        this.dpMobile = this.val('primaryPhone') || '\u2014';
        this.dpEmail = this.val('emailField') || '\u2014';
        const addr = this.buildPermAddr();
        this.dpAddress = addr || '\u2014';
    }

    /* ---------------- address builders ---------------- */
    buildAddr(houseNo, line, district, state, pin) {
        const parts = [];
        if (houseNo && houseNo.trim()) parts.push(houseNo.trim());
        if (line && line.trim()) parts.push(line.trim());
        if (district && district.trim()) parts.push(district.trim());
        if (state && state.trim()) parts.push(state.trim());
        let s = parts.join(', ');
        if (pin && pin.trim()) s += (s ? ' - ' : '') + pin.trim();
        return s;
    }
    buildPermAddr() {
        return this.buildAddr(this.val('houseNo'), this.val('permLine'), this.val('permDistrict'), this.val('permState'), this.val('permPin'));
    }

    /* ---------------- pattern validation ---------------- */
    handlePhoneInput(event) {
        this.checkField(event.target);
        this.refreshDpdp();
    }
    handleValidate(event) { this.checkField(event.target); }

    checkField(inp) {
        const kind = inp.getAttribute('data-validate');
        if (!kind) return true;
        const p = PATTERNS[kind];
        if (!p) return true;
        if (p.norm) { const nv = p.norm(inp.value); if (nv !== inp.value) inp.value = nv; }
        const hint = inp.closest('.eoi-field') ? inp.closest('.eoi-field').querySelector('.eoi-fielderr') : null;
        if (inp.value === '') { inp.classList.remove('invalid'); if (hint) hint.classList.add('hidden'); return true; }
        const ok = p.re.test(inp.value);
        if (ok) { inp.classList.remove('invalid'); if (hint) hint.classList.add('hidden'); }
        else { inp.classList.add('invalid'); if (hint) hint.classList.remove('hidden'); }
        return ok;
    }
    validatePatterns() {
        let all = true, firstBad = null;
        this.qa('[data-validate]').forEach(el => {
            if (el.value !== '' && !this.checkField(el)) { all = false; if (!firstBad) firstBad = el; }
        });
        return { ok: all, firstBad };
    }

    /* ---------------- Source Type -> Secondary ---------------- */
    handleSourceTypeChange(event) {
        const vals = this.sourceMap[event.target.value] || [];
        this.secondarySourceOptions = [...vals];
        const sec = this.byId('secondarySource');
        if (sec) sec.value = '';
    }

    /* ---------------- Channel Partner search ---------------- */
    handleCpFocus() { this.cpSearchNow(); }
    handleCpInput() {
        const hidden = this.byId('cpId');
        if (hidden) hidden.value = '';   // typing invalidates a prior pick
        if (this._cpTimer) clearTimeout(this._cpTimer);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._cpTimer = setTimeout(() => this.cpSearchNow(), 200);
    }
    cpSearchNow() {
        const term = this.val('cpSearch');
        searchChannelPartners({ term })
            .then(list => { this.cpResults = list || []; this.showCpResults = true; })
            .catch(() => { this.cpResults = []; this.showCpResults = true; });
    }
    handleCpSelect(event) {
        event.preventDefault(); // mousedown fires before blur so the pick registers
        const value = event.currentTarget.dataset.value;
        const label = event.currentTarget.dataset.label;
        const hidden = this.byId('cpId');
        const search = this.byId('cpSearch');
        const name = this.byId('cpName');
        if (hidden) hidden.value = value;
        if (search) search.value = label;
        if (name) name.value = label;
        this.showCpResults = false;
    }

    /* ---------------- files ---------------- */
    handleFileChange(event) {
        const inp = event.target;
        const cat = inp.dataset.category;
        const f = inp.files && inp.files[0];
        log('handleFileChange - category:', cat, '| file picked:', f ? f.name : 'NONE',
            '| size:', f ? f.size : '-', '| type:', f ? f.type : '-');
        if (!f) return;
        if (f.size > MAX_FILE) {
            log('handleFileChange - REJECTED, file too large');
            this.fail(f.name + ' is larger than 3 MB. Please upload a smaller file.');
            inp.value = '';
            return;
        }
        const isImg = (f.type || '').indexOf('image/') === 0;
        const reader = new FileReader();
        reader.onerror = () => {
            log('handleFileChange - FileReader error for', f.name);
            this.fail('Could not read ' + f.name);
        };
        reader.onload = () => {
            const dataUrl = String(reader.result || '');
            const c = dataUrl.indexOf(',');
            const b64 = c >= 0 ? dataUrl.substring(c + 1) : '';
            log('handleFileChange - read complete:', cat, '| base64 length:', b64 ? b64.length : 0);
            if (!b64) { this.fail(f.name + ' read as empty.'); return; }
            this.files[cat] = { fileName: f.name, title: cat, base64: b64 };
            log('handleFileChange - stored. total files now:', Object.keys(this.files).length);
            this.clearError();
            this.renderPreview(cat, f.name, isImg ? dataUrl : null);
        };
        reader.readAsDataURL(f);
    }
    renderPreview(category, name, imgUrl) {
        const next = this.filePreviews.filter(p => p.category !== category);
        next.push({ category, name, imgUrl });
        this.filePreviews = next;
    }

    /* ---------------- gather record from the DOM ---------------- */
    gather() {
        const rec = {};
        this.qa('[data-field]').forEach(el => {
            const key = el.getAttribute('data-field');
            if (el.type === 'checkbox') { rec[key] = el.checked; return; }
            const v = el.value;
            if (v !== null && v !== undefined && v !== '') rec[key] = v;
        });
        return rec;
    }
    gatherLead() {
        return {
            sourceType: this.val('sourceType'),
            secondary: this.val('secondarySource'),
            tertiary: this.val('tertiarySource')
        };
    }

    /* ---------------- validate ---------------- */
    validate() {
        this.clearError();
        let ok = true, firstBad = null;
        this.qa('[data-required="1"]').forEach(el => {
            if (!el.value) { ok = false; el.style.borderColor = '#c23934'; if (!firstBad) firstBad = el; }
            else { el.style.borderColor = ''; }
        });
        if (!ok) { this.fail('Please complete the highlighted required fields.'); if (firstBad) firstBad.focus(); return false; }

        const pv = this.validatePatterns();
        if (!pv.ok) { this.fail('Please correct the highlighted fields - check the format shown below each one.'); if (pv.firstBad) pv.firstBad.focus(); return false; }

        if (!this.byId('declCheck').checked) { this.fail('Please accept the Declaration before submitting.'); return false; }
        if (!this.byId('dpdpCheck').checked) { this.fail('Please provide DPDP consent before submitting.'); return false; }
        return true;
    }

    /* ---------------- submit ---------------- */
    handleSubmit() {
        if (!this.validate()) return;
        this.submitting = true;

        const rec = this.gather();
        rec.Permanent_Address__c = this.buildPermAddr();
        const commAddr = this.buildAddr('', this.val('commLine'), this.val('commDistrict'), this.val('commState'), this.val('commPin'));
        if (commAddr) rec.Communication_Address__c = commAddr;

        const fileArr = Object.keys(this.files).map(k => this.files[k]);

        // ---------------- DEBUG: what are we sending ----------------
        log('handleSubmit - files being sent:', fileArr.length);
        fileArr.forEach((f, i) => {
            log('  file[' + i + ']:', f.fileName,
                '| title:', f.title,
                '| base64 length:', f.base64 ? f.base64.length : 'EMPTY');
        });
        if (fileArr.length === 0) {
            log('handleSubmit - WARNING: no files in payload. Either none picked, or picked then submitted before they finished reading.');
        }
        // ------------------------------------------------------------

        submitEOI({ record: rec, filesJson: JSON.stringify(fileArr), leadInfo: this.gatherLead() })
            .then(res => {
                log('handleSubmit - server response:', JSON.stringify(res));
                this.refId = res.recordId;
                this.attachedCount = res.attached;
                this.filesReceived = res.filesReceived;
                this.attachErrorText = res.attachError || '(none)';
                if (res.attached === 0) {
                    log('handleSubmit - ATTACHED 0. filesReceived by server:', res.filesReceived,
                        '| attachError:', res.attachError);
                }
                this.submitted = true;
                this.scrollTop();
            })
            .catch(e => {
                log('handleSubmit - submit FAILED', e);
                this.submitting = false;
                this.fail(this.reason(e) || 'Submission failed. Please try again.');
            });
    }
}