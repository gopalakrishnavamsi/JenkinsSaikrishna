import {LightningElement, api} from 'lwc';
import {OperatorOptions} from 'c/queryUtils';
import orIfStatementLabel from '@salesforce/label/c.OrIfStatementUppercase';
import andIfStatementLabel from '@salesforce/label/c.AndIfStatementUppercase';
import ifStatementLabel from '@salesforce/label/c.IfStatement';
import orLabel from '@salesforce/label/c.or';
import andLabel from '@salesforce/label/c.andLabel';

export default class RuleCondition extends LightningElement {
    @api
    rule;

    @api
    fields;

    @api
    index = 0;

    @api
    ruleType = 'AND';

    @api
    lastIndex = 0;


    get objectFields() {
        return this.fields ? this.fields : [];
    }

    get isLast() {
        return this.index === this.lastIndex;
    }

    get clauseStatement() {
        return this.index === 0 ? ifStatementLabel : this.ruleType === 'AND' ? andIfStatementLabel : orIfStatementLabel;
    }

    get operatorOptions() {
        return Object.values(OperatorOptions);
    }

    get addLabel() {
        const value = this.ruleType === 'AND' ? andLabel : orLabel;
        return `+ ${value}`;
    }

    handleRuleChange = ({ target }) => {
        let rule = this.rule;
        if (!rule) return;
        
        const { name, value } = target;
        let canUpdate = true;
        switch(name) {
            case 'name':
                rule.fieldName = value;
                break;
            case 'operator':
                rule.matchType = value;
                break;
            case 'matchValue':
                rule.matchValue = value;
                break;
            default:
                canUpdate = false;
                break;
        }
        if (canUpdate) this.dispatchEvent(new CustomEvent('change', {
            detail: {
                index: this.index,
                rule: rule
            }
        }));   
    }

    addRule = () => {
        this.dispatchEvent(new CustomEvent('add'));  
    }

    cloneRule = () => {
        this.dispatchEvent(new CustomEvent('add', {
            detail: this.rule
        }));        
    }

    removeRule = () => {
        this.dispatchEvent(new CustomEvent('remove', {
            detail: this.index
        }));
    }
}