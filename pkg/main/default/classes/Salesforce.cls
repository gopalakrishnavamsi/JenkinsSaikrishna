//noinspection ApexModifierAgreement
public with sharing class Salesforce {

	private static final Map<String, SObjectType> GLOBAL_DESCRIBE;

	private static List<String> visualforceOrigins;
	private static List<String> lightningOrigins;
	private static List<String> communityOrigins;

	public static final Double API_VERSION = 48.0;

	@TestVisible
	public static String namespace { get; private set; }
	@TestVisible
	public static String instance { get; private set; }
	@TestVisible
	public static Url baseUrl { get; private set; }
	@TestVisible
	public static String sitePrefix { get; private set; }
	@TestVisible
	public static String edition { get; private set; }
	@TestVisible
	public static Boolean isSandbox { get; private set; }
	@TestVisible
	public static Boolean isApiSupported { get; private set; }
	@TestVisible
	public static Boolean isFlsSupported { get; private set; }
	@TestVisible
	public static Boolean isCommunitySite { get; private set; }
	@TestVisible
	public static Url oauthAudience { get; private set; }

	static {
		String siteBaseUrl = Site.getBaseUrl();
		baseUrl = String.isNotBlank(siteBaseUrl) ? new Url(siteBaseUrl) : Url.getOrgDomainUrl();
		sitePrefix = String.isNotBlank(Site.getPathPrefix()) ? Site.getPathPrefix() : '' ;
		Organization org = [
			SELECT InstanceName, IsSandbox, OrganizationType, NamespacePrefix
			FROM Organization
			LIMIT 1
		];
		instance = org.InstanceName.toLowerCase();
		isSandbox = org.IsSandbox;
		oauthAudience = String.isNotBlank(siteBaseUrl) ? new Url(siteBaseUrl)
			: new Url('https://' + (isSandbox ? 'test' : 'login') + '.salesforce.com');
		edition = org.OrganizationType;
		switch on (edition) {
			when 'Professional Edition' {
				isApiSupported = true;
				isFlsSupported = false;
			} when 'Enterprise Edition', 'Developer Edition', 'Unlimited Edition' {
				isApiSupported = true;
				isFlsSupported = true;
			} when else {
				// Group (Team), Essentials (Base?), Contact Manager, Personal
				// The picklist values don't have associated labels and they are not documented by Salesforce.
				// Furthermore, some of the values have changed in meaning over time.
				isApiSupported = false;
				isFlsSupported = false;
			}
		}
		namespace = org.NamespacePrefix;
		GLOBAL_DESCRIBE = Schema.getGlobalDescribe();
		isCommunitySite = Site.getSiteType() == 'ChatterNetwork';
	}

	public static SObjectType getSObjectType(final String typeName) {
		if (String.isBlank(typeName)) {
			throw new DocuSignException(
				String.format(Label.InvalidSObjectType_1,
					new List<String> {
						typeName
					})
			);
		}

		SObjectType result = GLOBAL_DESCRIBE.get(Application.resolveType(typeName).toLowerCase());
		if (result == null) {
			throw new DocuSignException(
				String.format(Label.InvalidSObjectType_1,
					new List<String> {
						typeName
					})
			);
		}

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
					Salesforce.instance,
					rootDomain
				});
			} else {
				result = String.format('https://{0}.{1}.{2}', new List<String> {
					myDomain,
					Salesforce.instance,
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
		if (Salesforce.visualforceOrigins == null) {
			String host = baseUrl.getHost();
			String myDomain = host.substringBefore('.');

			Salesforce.visualforceOrigins = new List<String> {
				getOrigin(
					myDomain,
					Application.namespace,
					null,
					'visualforce.com'),
				getOrigin(
					myDomain,
					Application.namespace,
					Salesforce.instance,
					'visual.force.com')
			};
		}
		return Salesforce.visualforceOrigins;
	}

	public static List<String> getCommunityOrigins() {
		if (Salesforce.communityOrigins == null) {
			if (isValidSObject('Network')) {
				Permissions.verifyIsQueryable(GLOBAL_DESCRIBE.get('Network'), new List<String> { 'Id' });
				List<SObject> networkData = Database.query('SELECT Id FROM Network WITH SECURITY_ENFORCED');
				List<String> communityUrls = new List<String>();
				if (Collection.isNotEmpty(networkData)) {
					for (SObject networkObj : networkData) {
						communityUrls.add(Network.getLoginUrl(networkObj.Id).removeEndIgnoreCase('/login'));
					}
					Salesforce.communityOrigins = communityUrls;
				}
			} else {
				Salesforce.communityOrigins = new List<String>();
			}
		}
		return Salesforce.communityOrigins;
	}

	public static List<String> getLightningOrigins() {
		if (Salesforce.lightningOrigins == null) {
			String host = baseUrl.getHost();
			String myDomain = host.substringBefore('.');

			Salesforce.lightningOrigins = new List<String> {
				getOrigin(
					myDomain,
					null,
					null,
					'lightning.force.com'),
				getOrigin(
					myDomain,
					null,
					Salesforce.instance,
					'lightning.force.com')
			};
		}
		return Salesforce.lightningOrigins;
	}

	public static Boolean isValidTarget(final String target) {
		//target is the window.location.origin passed from the visualforce page when the DocuSign OAuth is being triggered.
		//this is sometimes in a different case as compared to the myDomain names returned from Apex.
		//Hence we need to make a case insensitive comparison.
		Boolean result = false;
		List<String> visualForceOrigins = Salesforce.getVisualforceOrigins();
		List<String> lightningOrigins = Salesforce.getLightningOrigins();
		List<String> communityOrigins = Salesforce.getCommunityOrigins();
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
		if (communityOrigins != null && !communityOrigins.isEmpty() && !result) {
			for (String cmtyOrigin : communityOrigins) {
				if (cmtyOrigin.equalsIgnoreCase(target)) {
					result = true;
					break;
				}
			}
		}
		return result;
	}

	public static Boolean isValidSObject(final String sObjectName) {
		return String.isNotBlank(sObjectName)
			&& GLOBAL_DESCRIBE.containsKey(sObjectName.trim().toLowerCase());
	}

	public static SObjectType getParentSObjectType(
		final SObjectType baseSObject,
		final String referenceFieldName) {

		SObjectType parentSObjectType;
		Map<String, Schema.SObjectField> parentFieldsMap = baseSObject.getDescribe().fields.getMap();
		if (parentFieldsMap.containsKey(referenceFieldName)) {
			Schema.DescribeFieldResult dfr1 = parentFieldsMap.get(referenceFieldName).getDescribe();
			// removing 'Group,' if getReferenceTo() returns Owner as polymorphic field
			if (dfr1.getType() == Schema.DisplayType.REFERENCE && dfr1.getReferenceTo() != null) {
				String parentSObjectName = String.valueOf(dfr1.getReferenceTo()).remove('Group,').substringBetween('(', ')');
				parentSObjectType = Salesforce.getSObjectType(parentSObjectName);
			}
		}
		return parentSObjectType;
	}

	public static String getNamespace(final SObjectType type) {
		if (type == null) return '';

		String result = '';
		DescribeSObjectResult objDesc = type.getDescribe();
		if (objDesc.isCustom()) {
			String name = objDesc.getName().removeEnd('__c');
			result = name.contains('__') ? name.substringBefore('__') : '';
		}
		return result;
	}
}
