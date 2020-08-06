import {LightningElement,api} from 'lwc';
import {RuleTypes} from 'c/queryUtils';
import {isEmpty} from 'c/utils';
import getMergeFields from '@salesforce/apex/EnvelopeConfigurationController.getMergeFields';
import ofRuleConditionsLabel from '@salesforce/label/c.OfRuleConditions';
import applyUppercaseLabel from '@salesforce/label/c.ApplyUppercase';

export default class ConditionalLogic extends LightningElement {
    @api
    logic = { rulesList: [] };

    @api
    sourceObject;

    fields;

    privateRules;

    Labels = {
        ofRuleConditionsLabel,
        applyUppercaseLabel
    }

    get hasLogic() {
        return !isEmpty(this.logic);
    }

    get ruleTypeOptions() {
        return Object.values(RuleTypes);
    }

    get lastIndex() {
        return this.privateRules.length > 0 ? this.privateRules.length - 1 : 0;
    }

    connectedCallback(){ 
        if (this.logic && !this.privateRules) {
            this.privateRules = this.logic.rulesList;
        }
        if (!this.fields) {
            getMergeFields({
                sObjectType: this.sourceObject
            })
            .then(res => this.fields = res.filter(f => f.hasRelationship === false).map(f => {
                    return {
                        value: f.name,
                        label: f.label
                    }
                })
            ) 
            .catch(err => this.dispatchEvent(new CustomEvent('error', {
                detail: err
            })));
        }
    }

    handleLogicChange(logic){
        this.dispatchEvent(new CustomEvent('logicchange', {
            detail: logic
        }));
        this.privateRules = logic.rulesList;
    }

    handleRuleTypeChange = ({ target }) => {
        const value = target.value;
        let logic = this.logic;
        if (value === logic.type) return;
        logic.type = value;
        this.handleLogicChange(logic)
    }

    removeRule = ({ detail }) => {
        let logic = this.logic;
        logic.removeRule(detail)
        this.handleLogicChange(logic);
    }

    updateRule = ({ detail }) => {
        const { rule, index } = detail;
        if (isEmpty(rule) || isEmpty(index)) return;
        let logic = this.logic;
        logic.rules[index] = rule;
        this.handleLogicChange(logic);
    }

    addRule = ({ detail = {} }) => {
        let logic = this.logic;
        logic.addRule(detail ? detail : {});
        this.handleLogicChange(logic); 
    }
}