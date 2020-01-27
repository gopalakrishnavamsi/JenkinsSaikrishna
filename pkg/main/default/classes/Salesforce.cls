public with sharing class Salesforce {

	private static final Map<String, SObjectType> GLOBAL_DESCRIBE;
	private static final Boolean IS_CHATTER_ENABLED;
	private static final Boolean IS_CPQ_ENABLED;
	private static final Boolean ARE_CONTRACTS_ENABLED;
	private static final Boolean ARE_QUOTES_ENABLED;
	private static final Boolean ARE_WORK_ORDERS_ENABLED;
	private static final Boolean IS_COMMUNITY_SITE;
	private static final Url BASE_URL;
	@TestVisible
	private static final String INSTANCE_NAME;
	private static final String NAMESPACE_PREFIX;
	private static final Boolean IS_SANDBOX;
	private static final String ORG_TYPE;
	public static final Double API_VERSION = 47.0;

	private static List<String> visualforceOrigins;
	private static List<String> lightningOrigins;

	public static Url baseUrl {
		get {
			return BASE_URL;
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
	public static Url oauthUrl {
		get {
			return new Url(BASE_URL, '/services/oauth2/authorize');
		}
	}

	static {
		String siteBaseUrl = Site.getBaseUrl();
		BASE_URL = String.isNotBlank(siteBaseUrl) ? new Url(siteBaseUrl) : Url.getOrgDomainUrl();
		Organization org = [SELECT InstanceName, IsSandbox, OrganizationType, NamespacePrefix FROM Organization LIMIT 1];
		INSTANCE_NAME = org.InstanceName.toLowerCase();
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

	@TestVisible
	private static String getOrigin(
		final String myDomain,
		final String namespace,
		final String instance,
		final String rootDomain) {

		String result = null;

		// Add instance name to origin if critical update is disabled
		if (String.isNotBlank(instance)) {
			if (String.isNotBlank(namespace)) {
				result = String.format('https://{0}--{1}.{2}.{3}', new List<String> {
					myDomain,
					Application.namespace,
					INSTANCE_NAME,
					rootDomain
				});
			} else {
				result = String.format('https://{0}.{1}.{2}', new List<String> {
					myDomain,
					INSTANCE_NAME,
					rootDomain
				});
			}
		} else if (String.isNotBlank(namespace)) {
			result = String.format('https://{0}--{1}.{2}', new List<String> {
				myDomain,
				Application.namespace,
				rootDomain
			});
		} else {
			result = String.format('https://{0}.{1}', new List<String> {
				myDomain,
				rootDomain
			});
		}

		return result;
	}

	public static List<String> getVisualforceOrigins() {
		if (visualforceOrigins == null) {
			String host = BASE_URL.getHost();
			String myDomain = host.substringBefore('.');

			visualforceOrigins = new List<String> {
				getOrigin(
					myDomain,
					Application.namespace,
					null,
					'visualforce.com'),
				getOrigin(
					myDomain,
					Application.namespace,
					INSTANCE_NAME,
					'visual.force.com')
			};
		}
		return visualforceOrigins;
	}

	public static List<String> getLightningOrigins() {
		if (lightningOrigins == null) {
			String host = BASE_URL.getHost();
			String myDomain = host.substringBefore('.');

			lightningOrigins = new List<String> {
				getOrigin(
					myDomain,
					null,
					null,
					'lightning.force.com'),
				getOrigin(
					myDomain,
					null,
					INSTANCE_NAME,
					'lightning.force.com')
			};
		}
		return lightningOrigins;
	}

	public static Boolean isValidOrigin(final String origin) {
		//Make case insensitive comparison
		Boolean result = false;
		List<String> visualForceOrigins = getVisualforceOrigins();
		if (visualForceOrigins != null && !visualForceOrigins.isEmpty()) {
			for (String vfOrigin : visualForceOrigins) {
				if (vfOrigin.equalsIgnoreCase(origin)) {
					result = true;
					break;
				}
			}
		}
		return result;
	}

	public static Boolean isValidTarget(final String target) {
		//target is the window.location.origin passed from the visualforce page when the DocuSign OAuth is being triggered.
		//this is sometimes in a different case as compared to the myDomain names returned from Apex.
		//Hence we need to make a case insensitive comparison.
		Boolean result = false;
		List<String> visualForceOrigins = getVisualforceOrigins();
		List<String> lightningOrigins = getLightningOrigins();
		if (visualForceOrigins != null && !visualForceOrigins.isEmpty()) {
			for (String vfOrigin : visualForceOrigins) {
				if (vfOrigin.equalsIgnoreCase(target)) {
					result = true;
					break;
				}
			}
		}
		if (lightningOrigins != null && !lightningOrigins.isEmpty() && !result) {
			for (String ltngOrigin : lightningOrigins) {
				if (ltngOrigin.equalsIgnoreCase(target)) {
					result = true;
					break;
				}
			}
		}
		return result;
	}

	public static Boolean isValidSObject(String sObjectName) {
		return GLOBAL_DESCRIBE.containsKey(sObjectName);
	}

	public static SObjectType getParentSobjectType(SObjectType baseSObject, String referenceFieldName) {
		SObjectType parentSObjectType ;
		Map<String, Schema.SObjectField> parentFieldsMap = baseSObject.getDescribe().fields.getMap();
		if (parentFieldsMap.containsKey(referenceFieldName)) {
			Schema.DescribeFieldResult dfr1 = parentFieldsMap.get(referenceFieldName).getDescribe();
			// removing 'Group,' if getReferenceTo() returns Owner as polymorphic field
			if (dfr1.getType() == Schema.DisplayType.REFERENCE && dfr1.getReferenceTo() != null) {
				String parentSObjectName = String.valueOf(dfr1.getReferenceTo()).remove('Group,').substringBetween('(', ')');
				parentSObjectType = getSObjectType(parentSObjectName);
			}
		}
		return parentSObjectType;
	}

	public static Boolean checkIfMultiCurrencyIsEnabled() {
		return UserInfo.isMultiCurrencyOrganization();
	}
}
