public with sharing class Salesforce {

	private static final Map<String, SObjectType> GLOBAL_DESCRIBE;
	private static final Boolean IS_CHATTER_ENABLED;
	private static final Boolean IS_CPQ_ENABLED;
	private static final Boolean ARE_CONTRACTS_ENABLED;
	private static final Boolean ARE_QUOTES_ENABLED;
	private static final Boolean ARE_WORK_ORDERS_ENABLED;
	private static final Boolean IS_COMMUNITY_SITE;
	private static final Boolean CAN_USE_API;
	private static final Url BASE_URL;
	private static final String INSTANCE_NAME;
	private static final String NAMESPACE_PREFIX;
	private static final Boolean IS_SANDBOX;
	private static final String ORG_TYPE;
	public static final Double API_VERSION = 45.0;

	public static Url baseUrl {
		get {
			return BASE_URL;
		}
	}
	public static String instanceName {
		get {
			return INSTANCE_NAME;
		}
	}
	public static Boolean isSandbox {
		get {
			return IS_SANDBOX;
		}
	}
	public static String namespace {
		get {
			return NAMESPACE_PREFIX;
		}
	}
	public static String edition {
		get {
			return ORG_TYPE;
		}
	}
	public static Boolean isChatterEnabled {
		get {
			return IS_CHATTER_ENABLED;
		}
	}
	public static Boolean isCpqEnabled {
		get {
			return IS_CPQ_ENABLED;
		}
	}
	public static Boolean areContractsEnabled {
		get {
			return ARE_CONTRACTS_ENABLED;
		}
	}
	public static Boolean areQuotesEnabled {
		get {
			return ARE_QUOTES_ENABLED;
		}
	}
	public static Boolean areWorkOrdersEnabled {
		get {
			return ARE_WORK_ORDERS_ENABLED;
		}
	}
	public static Boolean isCommunitySite {
		get {
			return IS_COMMUNITY_SITE;
		}
	}
	public static Boolean canUseApi {
		get {
			return CAN_USE_API;
		}
	}
	public static Url oauthUrl {
		get {
			return new Url(BASE_URL, '/services/oauth2/authorize');
		}
	}

	static {
		String siteBaseUrl = Site.getBaseUrl();
		BASE_URL = String.isNotBlank(siteBaseUrl) ? new Url(siteBaseUrl) : Url.getOrgDomainUrl();
		Organization org = [SELECT InstanceName, IsSandbox, OrganizationType, NamespacePrefix FROM Organization LIMIT 1];
		INSTANCE_NAME = org.InstanceName;
		IS_SANDBOX = org.IsSandbox;
		ORG_TYPE = org.OrganizationType;
		NAMESPACE_PREFIX = org.NamespacePrefix;
		GLOBAL_DESCRIBE = Schema.getGlobalDescribe();
		ARE_CONTRACTS_ENABLED = GLOBAL_DESCRIBE.containsKey('Contract');
		ARE_QUOTES_ENABLED = GLOBAL_DESCRIBE.containsKey('QuoteDocument');
		ARE_WORK_ORDERS_ENABLED = GLOBAL_DESCRIBE.containsKey('WorkOrder');
		IS_CHATTER_ENABLED = GLOBAL_DESCRIBE.containsKey('FeedItem');
		IS_CPQ_ENABLED = GLOBAL_DESCRIBE.containsKey('SBQQ__QuoteDocument__c');
		IS_COMMUNITY_SITE = Site.getSiteType() == 'ChatterNetwork';
		CAN_USE_API = AccountSettings__c.getOrgDefaults().CanUseSalesforceApi__c;
	}

	public class MetadataApiNotSupportedException extends Exception {
	}

	@TestVisible
	private static Boolean isSObjectId(final String sObjectName, final Id sObjectId) {
		if (String.isBlank(sObjectId)) return false;

		SObjectType objectType;
		try {
			objectType = sObjectId.getSobjectType();
		} catch (SObjectException ex) {
			objectType = null;
		}
		if (objectType == null) return false;

		return objectType.getDescribe().getName() == sObjectName;
	}

	public static Boolean exists(final String sObjectType) {
		return exists(sObjectType, null);
	}

	public static Boolean exists(final String sObjectType, final Set<String> fields) {
		Boolean result = String.isNotBlank(sObjectType);
		if (result) {
			SObjectType t = GLOBAL_DESCRIBE.get(Application.resolveType(sObjectType).toLowerCase());
			if (t == null) {
				result = false;
			} else if (Collection.isNotEmpty(fields)) {
				Set<String> keys = t.getDescribe().fields.getMap().keySet();
				for (String f : fields) {
					result &= String.isNotBlank(f) && keys.contains(f.trim().toLowerCase());
				}
			}
		}
		return result;
	}

	public static SObjectType getSObjectType(final String typeName) {
		if (String.isBlank(typeName)) throw new DocuSignException(Label.InvalidType);

		SObjectType result = GLOBAL_DESCRIBE.get(Application.resolveType(typeName).toLowerCase());
		if (result == null) throw new DocuSignException(Label.InvalidType);

		return result;
	}

	/**
	  * Retrieves the name field for a Salesforce object type.
	  *
	  * @param type The Salesforce object type.
	  *
	  * @return The name field for the given object type.
	  */
	public static String getNameField(final SObjectType type) {
		String result = null;
		if (type != null) {
			for (SObjectField field : type.getDescribe().fields.getMap().values()) {
				DescribeFieldResult fieldDesc = field.getDescribe();
				if (fieldDesc.isNameField()) {
					result = fieldDesc.getName();
					break;
				}
			}
		}
		return result;
	}

	private static String getOrigin(
		final String domain,
		final Boolean useNamespace) {

		if (useNamespace) {
			return String.format('https://{0}--{1}.{2}', new List<String> {
				baseUrl.getHost().substringBefore('.'),
				Application.namespace,
				domain
			});
		}
		return String.format('https://{0}.{1}', new List<String> {
			baseUrl.getHost().substringBefore('.'),
			domain
		});
	}

	public static String getLightningOrigin(final Boolean useNamespace) {
		return getOrigin('lightning.force.com', useNamespace);
	}

	public static String getVisualforceOrigin(final Boolean useNamespace) {
		return getOrigin('visualforce.com', useNamespace);
	}

	public static Boolean isValidOrigin(final String origin) {
		Boolean result = false;
		if (String.isNotBlank(origin)) {
			try {
				Url u = new Url(origin);
				String host = u.getHost();
				result = u.getProtocol() == 'https'
					&& host.startsWith(baseUrl.getHost().substringBefore('.'))
					&& (host.endsWith('.lightning.force.com')
					|| host.endsWith('.visualforce.com'));
			} catch (Exception ex) {
				LoggerService.getInstance().exception(ex, 'Failed to validate origin: ' + origin);
			}
		}
		return result;
	}
}
