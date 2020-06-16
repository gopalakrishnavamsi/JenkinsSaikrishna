public with sharing class MergeService {

	private static final Pattern MERGE_FIELD_PATTERN = Pattern.compile('\\{!(\\$?\\w+)\\.([.\\w]+)}');
	@TestVisible
	private static final MergeService.Database DB = new MergeService.Database();

	@TestVisible
	private class Database {

		public SObject querySObject(
			final Id id,
			final List<String> fields) {

			SObject result = null;
			if (id != null && Collection.isNotEmpty(fields)) {
				result = (SObject)Collection.head(System.Database.query(String.format(
					'SELECT {0} FROM {1} WHERE Id = :id WITH SECURITY_ENFORCED LIMIT 1',
					new List<String> {
						String.escapeSingleQuotes(String.join(fields, ', ')),
						String.escapeSingleQuotes(id.getSobjectType().getDescribe().getName())
					})));
			}
			return result;
		}
	}

	/**
	 * Parses merge fields from an input string using Salesforce expressions. E.g.
	 * <code>{!Opportunity.Account.Name</code> or <code>{!$User.Email}</code>.
	 *
	 * @param input The input string to check.
	 * @param mergeFields Existing merge fields.
	 *
	 * @return Map of object name to map of field name to expression.
	 */
	public static Map<String, Map<String, String>> parseFields(
		final String input,
		Map<String, Map<String, String>> mergeFields) {

		if (mergeFields == null) {
			mergeFields = new Map<String, Map<String, String>>();
		}

		if (String.isNotBlank(input)) {
			Matcher m = MERGE_FIELD_PATTERN.matcher(input);
			while (m.find()) {
				String expression = m.group(0);
				String objectType = m.group(1);
				String field = m.group(2);
				Map<String, String> fieldExpressions = mergeFields.get(objectType);
				if (fieldExpressions == null) {
					mergeFields.put(objectType, new Map<String, String> {
						field => expression
					});
				} else {
					fieldExpressions.put(field, expression);
				}
			}
		}

		return mergeFields;
	}

	@TestVisible
	private static String valueOf(final Object obj) {
		if (obj == null) return '';

		// Date is serialized as Datetime when not reified. There may be other types requiring special handling.
		// Locale-based formatting shall be conveniently ignored.
		if (obj instanceof Date) {
			return String.valueOf((Date)obj);
		} else if (obj instanceof Datetime) {
			return String.valueOf((Datetime)obj);
		}

		return String.valueOf(obj);
	}

	@TestVisible
	private static String getValue(
		final SObject obj,
		final String field) {

		if (obj == null || String.isBlank(field)) return '';

		if (!field.contains('.')) {
			return obj.isSet(field) ? valueOf(obj.get(field)) : '';
		}

		return getValue(obj.getSObject(field.substringBefore('.')), field.substringAfter('.'));
	}

	/**
	 * Resolves merge field values.
	 *
	 * @param sourceId The Salesforce ID of the source object.
	 * @param mergeFields The merge fields to resolve.
	 *
	 * @return Map of merge field expressions to values.
	 */
	public static Map<String, String> resolveFields(
		final Id sourceId,
		final Map<String, Map<String, String>> mergeFields) {

		Map<String, String> result = new Map<String, String>(); // expression to value map
		if (String.isNotBlank(sourceId) && Collection.isNotEmpty(mergeFields)) {
			String sourceType = sourceId.getSobjectType().getDescribe().getName();

			for (String objectType : mergeFields.keySet()) {
				Map<String, String> fieldExpressions = mergeFields.get(objectType);
				List<String> fields = new List<String>(fieldExpressions.keySet());
				SObject obj = null;
				if (objectType == '$User') { // current user
					obj = DB.querySObject(UserInfo.getUserId(), fields);
				} else if (objectType == '$Organization') { // current org
					obj = DB.querySObject(UserInfo.getOrganizationId(), fields);
				} else if (objectType == sourceType) {
					obj = DB.querySObject(sourceId, fields);
				} else if (objectType != '$Recipient') {
					LoggerService.getInstance().warn('Cannot resolve type ' + objectType);
				}

				// Map the expressions to the resolved values
				for (String field : fields) {
					result.put(fieldExpressions.get(field), getValue(obj, field));
				}
			}
		}

		return result;
	}

	private static String parseFirstName(final String name) {
		String result = null;
		if (String.isNotBlank(name)) {
			result = (String)Collection.head(name.trim().split('\\s+'));
		}
		return result;
	}

	private static String parseLastName(final String name) {
		String result = null;
		if (String.isNotBlank(name)) {
			result = (String)Collection.last(name.trim().split('\\s+'));
		}
		return result;
	}

	@TestVisible
	private static String getRecipientValue(
		final String expression,
		final Recipient recipient) {

		String result = null;
		if (String.isNotBlank(expression) && recipient != null) {
			switch on expression {
				when '{!$Recipient.Name}' {
					result = recipient.name;
				} when '{!$Recipient.FirstName}' {
					result = parseFirstName(recipient.name);
				} when '{!$Recipient.LastName}' {
					result = parseLastName(recipient.name);
				} when '{!$Recipient.Email}' {
					result = recipient.email;
				} when '{!$Recipient.Phone}' {
					result = recipient.phone;
				} when '{!$Recipient.Role}' {
					if (recipient.role != null) result = recipient.role.name;
				}
			}
		}
		return result == null ? '' : result.trim();
	}

	/**
	 * Merges Salesforce data into a string.
	 *
	 * @param input The string with zero or more merge fields.
	 * @param mergeFields Map of merge field expressions to values. This is should be cached from a previous call to
	 * <code>resolveFields</code>.
	 * @param recipient Optional recipient to resolve <code>$Recipient</code> merge expressions.
	 *
	 * @return The string with Salesforce merge data.
	 */
	public static String mergeData(
		final String input,
		final Map<String, String> mergeFields,
		final Recipient recipient) {

		if (String.isBlank(input) || Collection.isEmpty(mergeFields)) return input;

		String result = input;
		Matcher m = MERGE_FIELD_PATTERN.matcher(input);
		while (m.find()) {
			String expression = m.group(0);
			if (expression.startsWith('{!$Recipient.')) {
				result = result.replace(expression, getRecipientValue(expression, recipient));
			} else {
				String value = mergeFields.get(expression);
				result = result.replace(expression, value == null ? '' : value);
			}
		}
		return result;
	}

	@TestVisible
	private static Map<String, DataModel.Relationship> buildRelationships(
		final SObjectType type,
		final Set<String> paths) {

		if (type == null || Collection.isEmpty(paths)) return new Map<String, DataModel.Relationship>();

		// Build FLS access map
		Map<String, DataModel.Relationship> result = new Map<String, DataModel.Relationship>();
		Map<SObjectType, Set<String>> accessMap = new Map<SObjectType, Set<String>>();
		for (String path : paths) {
			DataModel.buildAccessMap(type, path, result, accessMap);
		}

		// Check FLS for each object to update
		List<Permissions.FlsResults> failedFls = Permissions.checkAccess(
			Permissions.FlsAccess.Updateable,
			accessMap);
		if (Collection.isNotEmpty(failedFls)) {
			// String.join doesn't properly invoke FlsResults.toString() here, so need to build the long way.
			String message = '';
			Boolean first = true;
			for (Permissions.FlsResults fls : failedFls) {
				if (first) {
					message += String.valueOf(fls);
					first = false;
				} else {
					message += '\n' + String.valueOf(fls);
				}
			}

			throw UnauthorizedException.missingSecurityPermission(message);
		}

		return result;
	}

	@TestVisible
	private class FindQueryResult {
		public String path { get; private set; }
		public Query query { get; private set; }

		public FindQueryResult(
			final String path,
			final Query query) {

			this.path = path;
			this.query = query;
		}
	}

	@TestVisible
	private static FindQueryResult findParentQuery(
		final DataModel.Relationship relationship,
		final Map<String, Query> queries) {

		if (relationship == null || queries == null) return null;

		String path = relationship.name;
		Query query = null;
		DataModel.Relationship parent = relationship.parent;
		while (parent != null) {
			if (parent instanceof DataModel.ChildRelationship) {
				query = queries.get(parent.path);
				break;
			}
			path = parent.name + '.' + path;
			parent = parent.parent;
		}

		return new FindQueryResult(path, query);
	}

	@TestVisible
	private static Map<String, Query> addLookupQuery(
		final DataModel.LookupRelationship relationship,
		final List<String> fields,
		final Map<String, Query> queries) {

		if (relationship == null
			|| fields == null
			|| queries == null) {

			return queries == null ? new Map<String, Query>() : queries;
		}

		if (relationship.parent == null) {
			fields.add(relationship.name + '.Id');
		} else { // child relationship, add Id to sub-query
			FindQueryResult fqr = findParentQuery(relationship, queries);
			if (fqr == null || fqr.query == null) {
				fields.add((fqr == null ? relationship.name : fqr.path) + '.Id');
			} else {
				fqr.query.fields.add(fqr.path + '.Id');
			}
		}

		return queries;
	}

	@TestVisible
	private static Map<String, Query> addChildQuery(
		final DataModel.ChildRelationship relationship,
		final Map<String, Query> subQueries,
		final Map<String, Query> allQueries) {

		if (relationship == null
			|| subQueries == null
			|| allQueries == null) {

			return allQueries == null ? new Map<String, Query>() : allQueries;
		}

		Query q = null;
		if (relationship.parent == null
			|| !subQueries.containsKey(relationship.parent.path)) {

			q = Query.newSubQuery(
				String.valueOf(relationship.relatesTo),
				new List<String> { 'Id' },
				relationship.name,
				null,
				null,
				null,
				null);
			subQueries.put(relationship.path, q);
		} else {
			q = Query.newChildQuery(
				String.valueOf(relationship.relatesTo),
				new List<String> { 'Id' },
				relationship.name,
				String.valueOf(relationship.idField),
				null,
				null,
				null);
			subQueries.get(relationship.parent.path).children.add(q);
		}

		allQueries.put(relationship.path, q);

		return allQueries;
	}

	@TestVisible
	private static Query.Result querySObjects(
		final Id sourceId,
		final Map<String, DataModel.Relationship> relationships) {

		if (String.isBlank(sourceId)) return null;

		List<String> fields = new List<String> { 'Id' };
		Map<String, Query> subQueries = new Map<String, Query>();
		Map<String, Query> queries = new Map<String, Query>();
		if (Collection.isNotEmpty(relationships)) {
			List<DataModel.Relationship> rs = relationships.values();
			rs.sort();
			for (DataModel.Relationship r : rs) {
				if (r == null) continue;

				if (r instanceof DataModel.LookupRelationship) {
					addLookupQuery((DataModel.LookupRelationship)r, fields, queries);
				} else {
					addChildQuery((DataModel.ChildRelationship)r, subQueries, queries);
				}
			}
		}

		return Query.forUpdate(
			String.valueOf(sourceId.getSobjectType()),
			fields,
			subQueries.values())
			.execute(sourceId);
	}

	@TestVisible
	private static Map<Id, SObject> buildUpdates(
		final String path,
		final String location,
		final Object value,
		final List<SObject> objects,
		final Map<String, List<SObject>> descendants,
		final Map<String, DataModel.Relationship> relationships,
		Map<Id, SObject> result) {

		if (String.isBlank(path)
			|| String.isBlank(location)
			|| Collection.isEmpty(objects)) {

			return new Map<Id, SObject>();
		}

		if (result == null) result = new Map<Id, SObject>();

		String typePrefix = String.valueOf(objects[0].getSObjectType()) + '.'; // All must be same type
		String element = location.startsWithIgnoreCase(typePrefix)
			? location.substringAfter('.').substringBefore('.') : location.substringBefore('.');
		String remainder = location.startsWithIgnoreCase(typePrefix)
			? location.substringAfter('.').substringAfter('.') : location.substringAfter('.');
		if (String.isBlank(element)) return result;

		if (String.isBlank(remainder)) {
			for (SObject obj : objects) {
				if (obj == null) continue;

				if (result.containsKey(obj.Id)) {
					result.get(obj.Id).put(element, value);
				} else {
					obj.put(element, value);
					result.put(obj.Id, obj);
				}
			}
		} else if (descendants != null && descendants.containsKey(element)) {
			result.putAll(buildUpdates(
				path,
				remainder,
				value,
				descendants.get(element),
				descendants,
				relationships,
				result));
		} else if (relationships != null) {
			DataModel.Relationship r = relationships.get(path.substringBefore('.' + remainder));
			if (r != null) {
				List<SObject> nextObjects = new List<SObject>();
				if (r instanceof DataModel.LookupRelationship) {
					for (SObject obj : objects) {
						if (obj == null) continue;
						SObject next = obj.getSObject(element);
						if (next != null) nextObjects.add(next);
					}
				} else {
					for (SObject obj : objects) {
						if (obj == null) continue;
						List<SObject> next = obj.getSObjects(element);
						if (next != null) nextObjects.addAll(next);
					}
				}
				result.putAll(buildUpdates(
					path,
					remainder,
					value,
					nextObjects,
					descendants,
					relationships,
					result));
			}
		}

		return result;
	}

	/**
	 * Writes data back to a Salesforce source record.
	 *
	 * @param sourceId The Salesforce source record ID.
	 * @param dataUpdates A map of path to values for updates to perform.
	 *
	 * @return A list of the updated Salesforce objects.
	 */
	public static Map<Id, SObject> mergeData(
		final Id sourceId,
		final Map<String, Object> dataUpdates) {

		if (String.isBlank(sourceId) || Collection.isEmpty(dataUpdates)) return new Map<Id, SObject>();

		SObjectType type = sourceId.getSobjectType();

		// Also checks FLS here to avoid yet another loop
		Map<String, DataModel.Relationship> relationships = buildRelationships(
			type,
			dataUpdates.keySet());

		Query.Result queryResult = querySObjects(
			sourceId,
			relationships);

		Map<Id, SObject> result = new Map<Id, SObject>();
		if (queryResult != null && queryResult.result != null) {
			Map<String, List<SObject>> descendants = new Map<String, List<SObject>>();
			if (queryResult.children != null) {
				for (String key : queryResult.children.keySet()) {
					descendants.put(key.toLowerCase(), queryResult.children.get(key));
				}
			}

			for (String path : dataUpdates.keySet()) {
				result = buildUpdates(
					path,
					path,
					dataUpdates.get(path),
					new List<SObject> { queryResult.result },
					descendants,
					relationships,
					result);
			}
		}

		if (Collection.isNotEmpty(result)) {
			update result.values();
		}

		return result;
	}
}
