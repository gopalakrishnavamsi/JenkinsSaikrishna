/**
 * Source of truth for application metadata.
 */
public with sharing class Application {

	private static final String PACKAGE_NAMESPACE = 'dfsle';
	private static final String ORG_NAMESPACE_PREFIX;
	private static final String ORG_CLASS_NAMESPACE_PREFIX;
	private static final String NAMESPACE_PREFIX = 'dfsle__';
	private static final String CLASS_NAMESPACE_PREFIX = 'dfsle.';
	private static final Boolean IS_MANAGED_PACKAGE;
	private static final Version PACKAGE_VERSION;
	private static final String APPLICATION_NAME;
	private static final String USER_AGENT;
	private static final Set<String> APPLICATION_OBJECTS = new Set<String> {
		'envelopeconfiguration__c', 'customparametermap__c', 'customrecipient__c',
		'envelope__c', 'document__c', 'recipient__c',
		'status__c', 'recipientstatus__c', 'envelopelocalization__c',
		'accountsettings__c', 'usersettings__c', 'chattersettings__c', 'envelopesettings__c',
		'organization__mdt', 'localization__mdt', 'bulklist__c', 'bulkstatus__c',
		'gentemplate__c'
	};

	static {
		// HACK: Get managed package version: https://salesforce.stackexchange.com/questions/11049/cant-catch-system-procedureexception-thrown-by-system-requestversion
		Boolean result = null;
		try {
			result = UserInfo.isCurrentUserLicensed(PACKAGE_NAMESPACE);
			//UserInfo.isCurrentUserLicensed method has been deprecated post API version 45.0
			//Until we find a workaround for this method please do not update the API version of this Apex class.
		} catch (TypeException ex) {
			// Not managed
		}
		IS_MANAGED_PACKAGE = result != null;
		ORG_NAMESPACE_PREFIX = String.isNotBlank(Salesforce.namespace) ? Salesforce.namespace + '__' : '';
		ORG_CLASS_NAMESPACE_PREFIX = String.isNotBlank(Salesforce.namespace) ? Salesforce.namespace + '.' : '';

		// Don't call System.requestVersion outside managed package. It will throw an un-catchable ProcedureException.
		// Don't use versions < 1. They make SFDC unhappy.
		PACKAGE_VERSION = IS_MANAGED_PACKAGE ? System.requestVersion() : new Version(1, 0, 0);
		APPLICATION_NAME = 'DFS-LE ' + PACKAGE_VERSION;
		USER_AGENT = String.format('DFS-LE/{0} ({1}) SFDC-Callout/{2}', new List<String> {
			String.valueOf(PACKAGE_VERSION), UserInfo.getOrganizationId(), String.valueOf(Salesforce.API_VERSION)
		});
	}

	public static Boolean isManaged {
		get {
			return IS_MANAGED_PACKAGE;
		}
	}

	public static Version version {
		get {
			return PACKAGE_VERSION;
		}
	}

	public static String name {
		get {
			return APPLICATION_NAME;
		}
	}

	public static String packageNamespace {
		get {
			return PACKAGE_NAMESPACE;
		}
	}

	public static String namespacePrefix {
		get {
			return IS_MANAGED_PACKAGE ? NAMESPACE_PREFIX : ORG_NAMESPACE_PREFIX;
		}
	}

	public static String classNamespacePrefix {
		get {
			return IS_MANAGED_PACKAGE ? CLASS_NAMESPACE_PREFIX : ORG_CLASS_NAMESPACE_PREFIX;
		}
	}

	public static String namespace {
		get {
			return IS_MANAGED_PACKAGE ? PACKAGE_NAMESPACE : (String.isNotBlank(Salesforce.namespace) ? Salesforce.namespace : 'c');
		}
	}

	public static String userAgent {
		get {
			return USER_AGENT;
		}
	}

	public static String resolveType(final String sObjectType) {
		if (String.isBlank(sObjectType)) return null;

		String result = sObjectType.trim();
		if (APPLICATION_OBJECTS.contains(result.toLowerCase())) {
			return Application.namespacePrefix + result;
		}
		return result;
	}
}
