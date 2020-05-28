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

    get icon() {
        return `standard:${this.relatesTo.toLowerCase()}`;
    }    
}

export class Filter {
    constructor(filterBy = null, orderBy = null, maximumRecords = null) {
        this.filterBy = filterBy;
        this.orderBy = orderBy;
        this.maximumRecords = maximumRecords;
    }
}