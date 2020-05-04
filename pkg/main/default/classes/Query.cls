public with sharing class Query {

	public static final Integer MAXIMUM_RECORDS = 2000;

	public class Relationship {
		@AuraEnabled
		public Boolean isLookup { get; private set; }
		@AuraEnabled
		public String name { get; private set; }
		@AuraEnabled
		public String label { get; private set; }
		@AuraEnabled
		public String relatesTo { get; private set; }

		public Relationship(
			final Boolean isLookup,
			final String name,
			final String label,
			final String relatesTo) {

			this.isLookup = isLookup;
			this.name = name;
			this.label = label;
			this.relatesTo = relatesTo;
		}

		public SObjectType getType() {
			return Salesforce.getSObjectType(relatesTo);
		}
	}

	public class Filter {
		@AuraEnabled
		public String filterBy { get; private set; }
		@AuraEnabled
		public String orderBy { get; private set; }
		@AuraEnabled
		public Integer maximumRecords { get; private set; }

		public Filter(
			final String filterBy,
			final String orderBy,
			final Integer maximumRecords) {

			this.filterBy = filterBy;
			this.orderBy = orderBy;
			this.maximumRecords = maximumRecords > 0 ? maximumRecords : null;
		}
	}

	public class Result {
		@AuraEnabled
		public SObject result { get; private set; }
		@AuraEnabled
		public Map<String, List<SObject>> children { get; private set; }

		private Result(
			final SObject result,
			final Map<String, List<SObject>> children) {

			this.result = result;
			this.children = children == null ? new Map<String, List<SObject>>() : children;
		}
	}

	@AuraEnabled
	public String type;
	@AuraEnabled
	public List<String> fields { get; private set; }
	@AuraEnabled
	public String relationship { get; private set; }
	@AuraEnabled
	public String parentIdField { get; private set; }
	@AuraEnabled
	public String filterBy { get; private set; }
	@AuraEnabled
	public String orderBy { get; private set; }
	@AuraEnabled
	public Integer maximumRecords { get; private set; }
	@AuraEnabled
	public List<Query> children { get; private set; }

	@TestVisible
	private String soql;

	@TestVisible
	public Query(
		final String type,
		final List<String> fields,
		final String relationship,
		final String parentIdField,
		final String filterBy,
		final String orderBy,
		final Integer maximumRecords,
		final List<Query> children) {

		// No need to sanitize or otherwise prevent SOQL injection here. This builds a query according to the caller's
		// specification as intended. CRUD/FLS is checked up front for all objects and fields in the query.
		this.type = type;
		this.fields = fields == null ? new List<String> { 'Id' } : fields;
		this.relationship = relationship;
		this.parentIdField = parentIdField;
		this.filterBy = filterBy;
		this.orderBy = orderBy;
		this.maximumRecords = maximumRecords == null ? MAXIMUM_RECORDS : maximumRecords;
		this.children = children == null ? new List<Query>() : children;
	}

	private String getSubQuery() {
		String sq = String.format('SELECT {0} FROM {1}', new List<Object> {
			String.join(this.fields, ', '),
			this.relationship
		});
		if (String.isNotBlank(this.filterBy)) {
			sq += ' WHERE ' + this.filterBy;
		}
		if (String.isNotBlank(this.orderBy)) {
			sq += ' ORDER BY ' + this.orderBy;
		}
		return String.format('({0} LIMIT {1})', new List<Object> { sq, this.getLimit() });
	}

	private String getFields() {
		String result = String.join(this.fields, ', ');
		if (this.children != null) {
			for (Query q : this.children) {
				result += ', ' + q.getSubQuery();
			}
		}
		if (String.isNotBlank(this.parentIdField)) result += ', ' + this.parentIdField;
		return result;
	}

	private String getFilters() {
		String result = String.isBlank(this.parentIdField) ? 'Id = :sourceId' : this.parentIdField + ' IN :parentIds';
		if (String.isNotBlank(this.filterBy)) result += ' AND (' + this.filterBy + ' )';
		return result;
	}

	private String getOrdering() {
		return String.isBlank(this.orderBy) ? '' : ' ORDER BY ' + this.orderBy + ' ';
	}

	private Integer getLimit() {
		return this.maximumRecords == null || this.maximumRecords < 0 || this.maximumRecords > MAXIMUM_RECORDS
			? MAXIMUM_RECORDS : this.maximumRecords;
	}

	private String getSoql() {
		if (this.soql == null) {
			this.soql = String.format('SELECT {0} FROM {1} WHERE {2}{3} LIMIT {4}', new List<Object> {
				this.getFields(),
				this.type,
				this.getFilters(),
				this.getOrdering(),
				this.getLimit()
			});
		}
		return this.soql;
	}

	public static Query newQuery(
		final String type,
		final List<String> fields,
		final List<Query> subQueries) {

		Query q = new Query(
			type,
			fields,
			null,
			null,
			null,
			null,
			1,
			subQueries);
		validate(q);
		return q;
	}

	public static Query newSubQuery(
		final String type,
		final List<String> fields,
		final String relationship,
		final String filterBy,
		final String orderBy,
		final Integer maximumRecords,
		final List<Query> children) {

		return new Query(
			type,
			fields,
			relationship,
			null,
			filterBy,
			orderBy,
			maximumRecords,
			children);
	}

	public static Query newChildQuery(
		final String type,
		final List<String> fields,
		final String relationship,
		final String parentIdField,
		final String filterBy,
		final String orderBy,
		final Integer maximumRecords) {

		return new Query(
			type,
			fields,
			relationship,
			parentIdField,
			filterBy,
			orderBy,
			maximumRecords,
			null);
	}

	private static String getReferencePath(String name) {
		return name.endsWith('__r') ? name.replace('__r', '__c') : name + 'Id';
	}

	private static Map<SObjectType, List<String>> addAccessCheck(
		final SObjectType baseType,
		final String field,
		final Map<SObjectType, List<String>> accessMap) {

		if (String.isBlank(field) || accessMap == null) return accessMap;

		SObjectType type = baseType;
		String fieldName = field;
		if (field.contains('.')) {
			List<String> toks = field.split('\\.');
			if (toks.size() > MergeField.MAX_DEPTH) throw new DocuSignException(Label.MaxObjectDepthExceeded);
			String parentType = toks[0];
			type = Salesforce.isValidSObject(parentType)
				? Salesforce.getSObjectType(parentType)
				: Salesforce.getParentSObjectType(baseType, getReferencePath(parentType));
			fieldName = toks[1];
		}

		if (accessMap.containsKey(type)) {
			accessMap.get(type).add(fieldName);
		} else {
			accessMap.put(type, new List<String> { fieldName });
		}

		return accessMap;
	}

	private static String formatMessage(
		final String type,
		final String parentType,
		final String relationship,
		final String message) {

		String path = String.isBlank(parentType) || String.isBlank(relationship)
			? type : parentType + '.' + relationship;
		return String.format(Label.QueryError_2, new List<String> { path, message });
	}

	private static ValidationResult validateAccess(final Query query) {
		if (query == null || String.isBlank(query.type)) return null;

		SObjectType type = Salesforce.getSObjectType(query.type);
		Map<SObjectType, List<String>> accessMap = new Map<SObjectType, List<String>> {
			type => new List<String>()
		};

		for (String field : query.fields) {
			if (String.isNotBlank(field)) addAccessCheck(type, field, accessMap);
		}

		for (Query childQuery : query.children) {
			if (Collection.isNotEmpty(childQuery.children)) {
				for (Query childQuery2 : childQuery.children) {
					for (String field : childQuery2.fields) {
						addAccessCheck(Salesforce.getSObjectType(childQuery2.type), field, accessMap);
					}
				}
			}
		}

		ValidationResult result = new ValidationResult();
		for (SObjectType t : accessMap.keySet()) {
			result.add(Permissions.isQueryable(t, accessMap.get(t)));
		}
		return result;
	}

	//noinspection ApexUnusedDeclaration // needed to validate SOQL
	private static ValidationResult validateSoql(
		final Query query,
		final String parentType) {

		if (query == null) return null;

		ValidationResult result = new ValidationResult();
		// Set limit to zero to not actually return rows.
		String testSoql = query.getSoql().replaceFirst('LIMIT\\s+\\d+', 'LIMIT 0');
		// These are the only allowable SOQL variables. These need to be defined for the query to validate.
		Id sourceId = UserInfo.getUserId();
		Set<Id> parentIds = new Set<Id>();
		try {
			Database.query(testSoql);
		} catch (QueryException ex) {
			result.add(formatMessage(query.type, parentType, query.relationship,
				String.format(Label.InvalidSoql_2, new List<Object> { testSoql, ex.getMessage() })));
		}
		return result;
	}

	@TestVisible
	private static ValidationResult validate(
		final Query query,
		final String parentType,
		final Integer depth) {

		// 1. Check that query has required parameters defined and valid.
		if (query == null) return new ValidationResult(Label.UndefinedArgument);
		if (String.isBlank(query.type)) return new ValidationResult(Label.UndefinedType);

		ValidationResult result = new ValidationResult();

		if (depth == 1) {
			if (String.isNotBlank(query.filterBy)) {
				result.add(formatMessage(query.type, null, null,
					Label.CannotFilterSourceObjectResults));
			}
			if (String.isNotBlank(query.orderBy)) {
				result.add(formatMessage(query.type, null, null,
					Label.CannotOrderSourceObjectResults));
			}
			if (query.maximumRecords != null && query.maximumRecords != 1) {
				result.add(formatMessage(query.type, null, null,
					Label.CannotLimitSourceObjectResults));
			}
		} else if (query.maximumRecords <= 0 || query.maximumRecords > MAXIMUM_RECORDS) {
			result.add(formatMessage(query.type, parentType, query.relationship,
				String.format(Label.InvalidLimit_1, new List<Object> { MAXIMUM_RECORDS })));
		}

		if (Collection.isNotEmpty(query.children) && depth > MergeField.MAX_CHILD_DEPTH) {
			result.add(formatMessage(query.type, parentType, query.relationship,
				String.format(Label.MaxDescendantQueryDepthExceeded_1,
					new List<Object> { MergeField.MAX_CHILD_DEPTH })));
		} else {
			for (Query childQuery : query.children) {
				if (String.isBlank(childQuery.relationship)) {
					result.add(formatMessage(childQuery.type, query.type, null,
						Label.UndefinedChildRelationship));
				}
				if (depth > 1 && String.isBlank(childQuery.parentIdField)) {
					result.add(formatMessage(childQuery.type, query.type, childQuery.relationship,
						Label.UndefinedParent));
				}
				result.add(validate(childQuery, query.type, depth + 1));
			}
		}

		// 2. Check CRUD/FLS for requested objects and fields.
		result = result.add(validateAccess(query));

		// 3. Check validity of generated SOQL.
		if (result.isValid) {
			result = result.add(validateSoql(query, parentType));
			for (Query subQuery : query.children) {
				for (Query childQuery : subQuery.children) {
					result = result.add(validateSoql(childQuery, subQuery.type));
				}
			}
		}

		return result;
	}

	public static void validate(final Query query) {
		ValidationResult result = validate(query, null, 1);
		if (!result.isValid) throw new ValidationException(Label.InvalidQuery, result);
	}

	public static void validate(final Query query, final Integer depth) {
		ValidationResult result = validate(query, null, depth);
		if (!result.isValid) throw new ValidationException(Label.InvalidQuery, result);
	}

	private List<SObject> queryChildren(
		final SObject root,
		final String rootRelationship,
		final Query childQuery) {

		Set<Id> parentIds = new Set<Id>();
		for (SObject parent : root.getSObjects(rootRelationship)) {
			if (parent != null && String.isNotBlank(parent.Id)) {
				parentIds.add(parent.Id);
			}
		}

		return Collection.isEmpty(parentIds) ? new List<SObject>() : Database.query(childQuery.getSoql());
	}

	//noinspection ApexUnusedDeclaration // sourceId is SOQL variable
	public Result execute(final Id sourceId) {
		// Query root object with 1 level of sub-queries
		SObject result = Database.query(this.getSoql());

		// Query children
		Map<String, List<SObject>> children = new Map<String, List<SObject>>();
		for (Query subQuery : this.children) {
			for (Query childQuery : subQuery.children) {
				List<SObject> childResult = queryChildren(result, subQuery.relationship, childQuery);
				if (children.containsKey(childQuery.relationship)) {
					children.get(childQuery.relationship).addAll(childResult);
				} else {
					children.put(childQuery.relationship, childResult);
				}
			}
		}

		return new Result(result, children);
	}

	//noinspection ApexUnusedDeclaration // sourceId is SOQL variable
	public Boolean hasRecord(final Id sourceId) {
		return Database.query(this.getSoql()).size() > 0;
	}
}
