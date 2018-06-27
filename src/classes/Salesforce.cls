public with sharing class Salesforce {

	private static final Map<String, SObjectType> GLOBAL_DESCRIBE;
	private static final Boolean IS_CHATTER_ENABLED;
	private static final Boolean IS_CPQ_ENABLED;
	private static final Boolean ARE_CONTRACTS_ENABLED;
	private static final Boolean ARE_QUOTES_ENABLED;
	private static final Boolean ARE_WORK_ORDERS_ENABLED;
	private static final Boolean IS_COMMUNITY_SITE;
	private static final Boolean CAN_USE_API;
	public static final String BASE_Url;
	public static final Double API_VERSION = 43.0;
	public static final String MAGIC_PARAMETER = 'isdtp';
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

	static {
		String siteBaseUrl = Site.getBaseUrl();
		BASE_Url = String.isNotBlank(siteBaseUrl) ? siteBaseUrl : Url.getSalesforceBaseUrl().toExternalForm();
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

	public enum Environment {
		Production, Sandbox
	}

	public class Configuration {
		public String host { get; private set; }   // this is a host name got from HTTP headers
		public String baseUrl { get; private set; } // this is a host name in https://XXX.salesforce.com format

		public Configuration(final String host, final String baseUrl) {
			this.host = host;
			this.baseUrl = baseUrl;
		}
	}

	public class MergeObject implements Comparable {
		public String name { get; private set; }
		public String label { get; private set; }
		public Boolean isUpdateable { get; private set; }

		public MergeObject(final String name, final String label, final Boolean isUpdateable) {
			this.name = name;
			this.label = label;
			this.isUpdateable = isUpdateable;
		}

		public Integer compareTo(final Object compareTo) {
			MergeObject other = (MergeObject)compareTo;
			if (this.label == other.label) return 0;
			if (this.label > other.label) return 1;
			return -1;
		}
	}

	public class MergeField implements Comparable {
		public Integer level { get; private set; }
		public String type { get; private set; }
		public String name { get; private set; }
		public String label { get; private set; }
		public String reference { get; private set; }
		public List<String> picklistValues { get; private set; }
		public Boolean isUpdateable { get; private set; }

		public MergeField(final Integer level, final String type, final String name, final String label,
			final String reference, final List<String> picklistValues, final Boolean isUpdateable) {

			this.level = level;
			this.type = type;
			this.name = name;
			this.label = label;
			this.reference = reference;
			this.picklistValues = picklistValues == null ? new List<String>() : picklistValues;
			this.isUpdateable = isUpdateable;
		}

		public Integer compareTo(final Object compareTo) {
			MergeField other = (MergeField)compareTo;
			if (this.label == other.label) return 0;
			if (this.label > other.label) return 1;
			return -1;
		}
	}

	@TestVisible
	private static Boolean isSObjectId(final String sObjectName, final Id sObjectId) {
		if (String.isBlank(sObjectId)) return false;

		SObjectType objectType;
		try {
			objectType = sObjectId.getSObjectType();
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

	public static String getLightningHost() {
		String host = Url.getSalesforceBaseUrl().getHost();
		return host.substringBefore('.').remove('--c').remove('--' + Application.packageNamespace)
			+ '.lightning.force.com';
	}
}
