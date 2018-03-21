@IsTest
private class ApplicationTest {

	static testMethod void test_isManaged() {
		Boolean isManaged = false;
		try {
			UserInfo.isCurrentUserLicensed('dfsle');
			isManaged = true;
		} catch (TypeException ex) {
			// Not managed
		}

		System.assertEquals(isManaged, Application.isManaged);
	}

	static testMethod void test_version() {
		System.assertEquals(Application.isManaged ? System.requestVersion() : new Version(1, 0, 0), Application.version);
	}

	static testMethod void test_name() {
		System.assertEquals('DFS-LE ' + (Application.isManaged ? System.requestVersion() : new Version(1, 0, 0)), Application.name);
	}

	static testMethod void test_namespacePrefix() {
		String orgNS = [SELECT NamespacePrefix FROM Organization LIMIT 1].NamespacePrefix;
		System.assertEquals(Application.isManaged ? 'dfsle__' : (String.isNotBlank(orgNS) ? orgNS + '__' : ''), Application.namespacePrefix);
	}

	static testMethod void test_classNamespacePrefix() {
		String orgNS = [SELECT NamespacePrefix FROM Organization LIMIT 1].NamespacePrefix;
		System.assertEquals(Application.isManaged ? 'dfsle.' : (String.isNotBlank(orgNS) ? orgNS + '.' : ''), Application.classNamespacePrefix);
	}

	static testMethod void test_userAgent() {
		System.assertEquals(String.format('DFS-LE/{0} ({1}) SFDC-Callout/{2}', new List<String> {
			String.valueOf(Application.version), UserInfo.getOrganizationId(), String.valueOf(Salesforce.API_VERSION)
		}), Application.userAgent);
	}

	static testMethod void test_resolveType() {
		Test.startTest();
		System.assertEquals(null, Application.resolveType(null));
		System.assertEquals(null, Application.resolveType(''));
		System.assertEquals(null, Application.resolveType('\t'));
		System.assertEquals('Account', Application.resolveType('  Account'));
		System.assertEquals(Application.namespacePrefix + 'Envelope__c', Application.resolveType('Envelope__c\n'));
		Test.stopTest();
	}
}
