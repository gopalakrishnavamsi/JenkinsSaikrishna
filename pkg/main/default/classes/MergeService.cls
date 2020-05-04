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
}
