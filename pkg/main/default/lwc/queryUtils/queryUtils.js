import anyLabel from '@salesforce/label/c.Any';
import allLabel from '@salesforce/label/c.All';
import equalsLabel from '@salesforce/label/c.Equals';
import notEqualsLabel from '@salesforce/label/c.DoesNotEqual';
import containsLabel from '@salesforce/label/c.ContainsLabel';
import greaterThanLabel from '@salesforce/label/c.GreaterThanLabel';
import lessThanLabel from '@salesforce/label/c.LessThanLabel';
import greaterThanOrEqualsLabel from '@salesforce/label/c.GreaterThanOrEqualsLabel';
import lessThanOrEqualsLabel from '@salesforce/label/c.LessThanOrEqualsLabel';
import soqlSortingLabel from '@salesforce/label/c.OrderByOption';
import maximumRecordsPulledLabel from '@salesforce/label/c.MaximumRecordsPulled';
import orderedByLabel from '@salesforce/label/c.OrderedBy';
import recentDateCreatedLabel from '@salesforce/label/c.RecentDateCreated';
import recentDateModifiedLabel from '@salesforce/label/c.RecentDateModified';
import otherCustomSOQLLabel from '@salesforce/label/c.OtherCustomSOQL';
import startsWithLabel from '@salesforce/label/c.StartsWithLabel';
import endsWithLabel from '@salesforce/label/c.EndsWithLabel';


import { isEmpty, getRandomKey } from 'c/utils';

export const RuleTypes = {
    all: {
        label: allLabel,
        value: 'AND'
    },    
    any: {
        label: anyLabel,
        value: 'OR'
    }
}

export const OperatorOptions = {
    Equals : {
        label : equalsLabel,
        value: 'Equals',
        operator: '='
    },
    Contains: {
        label: containsLabel,
        value: 'Contains',
        operator: 'LIKE'
    },
    StartsWith: {
        label: startsWithLabel,
        value: 'StartsWith',
        operator: 'LIKE'
    },
    EndsWith: {
        label: endsWithLabel,
        value: 'EndsWith',
        operator: 'LIKE'
    },        
    NotEquals: {
        label: notEqualsLabel,
        value: 'NotEquals',
        operator: '!='
    },
    GreaterThan: {
        label: greaterThanLabel,
        value: 'GreaterThan',
        operator: '>'
    },
    LessThan: {
        label: lessThanLabel,
        value: 'LessThan',
        operator: '<'        
    },
    LessThanOrEquals: {
        label: lessThanOrEqualsLabel,
        value: 'LessThanOrEquals',
        operator: '<='         
    },
    GreaterThanOrEquals: {
        label: greaterThanOrEqualsLabel,
        value: 'GreaterThanOrEquals',
        operator: '>='         
    }    
};

const LogicOperators = {
    '=' : OperatorOptions.Equals.value,
    'LIKE' : OperatorOptions.Contains.value,
    '<>': OperatorOptions.NotEquals.value,
    '!=': OperatorOptions.NotEquals.value,
    '>' : OperatorOptions.GreaterThan.value,
    '<' : OperatorOptions.LessThan.value,
    '>=' : OperatorOptions.GreaterThanOrEquals.value,
    '<=' : OperatorOptions.LessThanOrEquals.value 
};

export const Labels = {
    soqlSortingLabel,
    maximumRecordsPulledLabel,
    orderedByLabel
}

export const OrderByQueriesOptions = {
    MostRecent : {
        label: recentDateCreatedLabel,
        value: 'MostRecent',
        query: 'CreatedDate DESC'
    },
    LastModified : {
        label: recentDateModifiedLabel,
        value: 'LastModified',
        query: 'LastModifiedDate DESC'
    },
    Custom : {
        label: otherCustomSOQLLabel,
        value: 'Custom',
        query: null
    }
}

export class Relationship {
    constructor(isLookup = true, name = null, label = null, relatesTo = null) {
        this.isLookup = isLookup;
        this.name = name;
        this.label = label;
        this.relatesTo = relatesTo;
    }

    static fromObject({ isLookup = true, name = null, label = null, relatesTo = null }) {
        return new Relationship(isLookup, name, label, relatesTo);
    }

    get isEmpty() {
        return isEmpty(this.name) || isEmpty(this.label) || isEmpty(this.relatesTo);
    }

    get icon() {
        return !isEmpty(this.relatesTo) ? `standard:${this.relatesTo.toLowerCase()}` : null;
    }    
}

export class Filter {
    constructor(filterBy = null, orderBy = null) {
        this.filterBy = filterBy;
        this.orderBy = orderBy;
        this.maximumRecords = 1;
    }

    static fromObject({ filterBy = null, orderBy = null}) {
        return new Filter(filterBy, orderBy);
    }

    get isEmpty() {
        return isEmpty(this.filterBy) && isEmpty(this.orderBy);
    }

    get orderByType() {
        if (isEmpty(this.orderBy)) return null;
        const orderByValue = this.orderBy.toUpperCase();
        if (orderByValue === OrderByQueriesOptions.MostRecent.query.toUpperCase()) return OrderByQueriesOptions.MostRecent.value;
        else if (orderByValue === OrderByQueriesOptions.LastModified.query.toUpperCase()) return OrderByQueriesOptions.LastModified.value;
        return OrderByQueriesOptions.Custom.value;
    }

    equals({ filterBy = null, orderBy = null}) {
        return this.filterBy === filterBy && this.orderBy === orderBy;
    }    

    getConditionalLogic() {
        return new Promise((resolve, reject) => {
            try {
                if (isEmpty(this.filterBy)) resolve(new ConditionalLogic());
                let clause = this.filterBy.toUpperCase();
                const hasOR = clause.indexOf(RuleTypes.any.value) > -1;
                const hasAND = clause.indexOf(RuleTypes.all.value) > -1;
                if (hasAND && hasOR) {
                    reject('Invalid filter by');
                } else if (hasOR) {
                    resolve(parseFilterBy(this.filterBy, RuleTypes.any.value))
                } else {
                    //Default to AND for single conditional filterBy
                    resolve(parseFilterBy(this.filterBy, RuleTypes.all.value))
                }
            } catch(err) {
                reject(err);
            }
        })
    }
}

class ConditionalLogic {
    constructor(type = RuleTypes.all.value, rules = {}) {
        this.rules = rules;
        this.type = type;
    }

    get rulesList() {
        return Object.values(this.rules)
    }

    get hasRules() {
        return !isEmpty(this.rules) && this.rules.length > 0;
    }

    addRule(details = {}) {
        this.rules[Object.keys(this.rules).length] = new Rule(details);
    }

    removeRule(index) {
        delete this.rules[index];
        this.rules = {...this.rulesList};
    }

    toString() {
        let filterBy = [];
        for (const rule of this.rulesList) {
            if (!rule.isValid) continue;
            filterBy.push(rule.toString());
        }
        return filterBy.length > 0 ? filterBy.join(` ${this.type} `) : null;
    }
}

class Rule {
    constructor({ fieldName = null, matchType = OperatorOptions.Equals.value, matchValue = null, isString = true }) {
        this.fieldName = fieldName;
        this.matchType = matchType;
        this.matchValue = matchValue;
        this.isString = isString;
        this.key = getRandomKey();
    }

    get operator() {
        return this.matchType ? OperatorOptions[this.matchType].operator : null;
    }

    get isValid() {
        return !isEmpty(this.fieldName) && !isEmpty(this.operator) && !isEmpty(this.matchValue);
    }

    get formattedValue() {
        return isWildCardOperator(this.matchType) ? 
        getWildCardValue(
            this.matchValue, 
            this.matchType === OperatorOptions.Contains.value || this.matchType === OperatorOptions.StartsWith.value,
            this.matchType === OperatorOptions.Contains.value || this.matchType === OperatorOptions.EndsWith.value,
            ) : this.matchValue;
    }

    toString() {
        return this.isValid ? `${this.fieldName} ${this.operator} ${this.formattedValue}` : '';
    }
}

const isWildCardOperator = matchType => {
    return matchType === OperatorOptions.Contains.value 
        || matchType === OperatorOptions.StartsWith.value
        || matchType === OperatorOptions.EndsWith.value
}

const getMatchType = (operator, value) => {
    const formmatedValue = value.trim().replace(/['"]+/g, '');
    const hasLeftWildCard = formmatedValue.charAt(0) === '%';
    const hasRightWildCard = formmatedValue.charAt(formmatedValue.length - 1) === '%';

    if (hasLeftWildCard && hasRightWildCard) return OperatorOptions.Contains.value;
    if (hasLeftWildCard) return OperatorOptions.StartsWith.value;
    if (hasRightWildCard) return OperatorOptions.EndsWith.value;
    
    return LogicOperators[operator];
}

const getWildCardValue = (val, hasLeft = false, hasRight = false) => {
    if (isEmpty(val)) return null;
    const isString = val.match(/'(?:[^'\\]|\\.)*'/) !== null;
    const formmatedValue = isString ? val.replace(/['"]+/g, '') : val;
    return isString ? `'${hasLeft ? '%' : ''}${formmatedValue}${hasRight ? '%' : ''}'` : `${formmatedValue}%`
}

const parseFilterBy = (filterBy, matchType) => {
    if (!matchType) throw 'invalid matchType';

    const statements = filterBy.split(new RegExp(` ${matchType.toUpperCase()} `));
    const rules = statements && statements.length > 0 ? statements.map(r => parseRule(r)) : [];
    return new ConditionalLogic(matchType, {...rules});
}

const parseRule = (rule) => {
    let isValid = false;
    let operator;
    for (const key in LogicOperators) { 
        const hasValue = rule.indexOf(key) > -1;
        if (hasValue && isValid) {
            //Multiple operators: Todo add support
            isValid = false;
            throw 'Unsupported query';
        } else if (hasValue) {
            isValid = true; 
            operator = key;
        }
    }

    if (!isValid) throw 'Invalid query, statement is missing operator';

    let [ fieldName = '', matchValue = '' ] = rule.split(operator);
    matchValue = matchValue.trim();
    const matchType = getMatchType(operator, matchValue);
    return new Rule({ 
        fieldName: fieldName.trim(), 
        matchValue : isWildCardOperator(matchType) ? matchValue.replace(/%/g, '') : matchValue, 
        matchType: matchType 
    });
}