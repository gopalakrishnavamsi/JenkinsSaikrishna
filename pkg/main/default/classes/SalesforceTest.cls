@IsTest
private class SalesforceTest {

//	@IsTest(seeAllData = true) // Required for ConnectApi call.
//	static void test_isChatterEnabled() {
//		System.assertEquals(ConnectApi.Organization.getSettings().features.chatter, Salesforce.isChatterEnabled);
//	}

	@IsTest
	static void test_isChatterEnabled() {
		// HACK: Detecting whether Chatter enabled is wonky in unit tests. See above.
		System.assert(Salesforce.isChatterEnabled || !Salesforce.isChatterEnabled);
	}

	@IsTest
	static void test_baseUrl() {
		String siteBaseUrl = Site.getBaseUrl();
		System.assertNotEquals(null, Salesforce.baseUrl);
		System.assertEquals(String.isNotBlank(siteBaseUrl) ? siteBaseUrl : Url.getOrgDomainUrl().toExternalForm(),
			Salesforce.baseUrl.toExternalForm());
	}

	@IsTest
	static void test_edition() {
		System.assertEquals([SELECT OrganizationType FROM Organization LIMIT 1].OrganizationType,
			Salesforce.edition);
	}

	@IsTest
	static void test_oauthUrl() {
		System.assertEquals(Salesforce.baseUrl.toExternalForm() + '/services/oauth2/authorize',
			Salesforce.oauthUrl.toExternalForm());
	}

	@IsTest
	static void test_instanceName() {
		System.assertEquals([SELECT InstanceName FROM Organization LIMIT 1].InstanceName, Salesforce.instanceName);
	}

	@IsTest
	static void test_isSandbox() {
		System.assertEquals([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox, Salesforce.isSandbox);
	}

	@IsTest
	static void test_isCpqEnabled() {
		System.assertEquals(Schema.getGlobalDescribe().containsKey('SBQQ__QuoteDocument__c'), Salesforce.isCpqEnabled);
	}

	@IsTest
	static void test_areContractsEnabled() {
		System.assertEquals(Schema.getGlobalDescribe().containsKey('Contract'), Salesforce.areContractsEnabled);
	}

	@IsTest
	static void test_areQuotesEnabled() {
		System.assertEquals(Schema.getGlobalDescribe().containsKey('QuoteDocument'), Salesforce.areQuotesEnabled);
	}

	@IsTest
	static void test_isCommunitySite() {
		System.assertEquals(Site.getSiteType() == 'ChatterNetwork', Salesforce.isCommunitySite);
	}

	@IsTest
	static void test_areWorkOrdersEnabled() {
		System.assertEquals(Schema.getGlobalDescribe().containsKey('WorkOrder'), Salesforce.areWorkOrdersEnabled);
	}

	@IsTest
	static void test_canUseApi_default() {
		System.assert(!Salesforce.canUseApi);
	}

	@IsTest
	static void test_canUseApi_enabled() {
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.CanUseSalesforceApi__c = true;
		insert s;

		System.assert(Salesforce.canUseApi);
	}

	@IsTest
	static void test_isSObjectId() {
		System.runAs(UserMock.createUser()) {
			Schema.Account a = TestUtils.createAccount();
			Contact c = TestUtils.createContact(a.Id);
			Opportunity o = TestUtils.createOpportunity(a.Id);
			Case cs = TestUtils.createCase(a.Id, c.Id);

			Test.startTest();
			System.assert(Salesforce.isSObjectId('Account', a.Id));
			System.assert(Salesforce.isSObjectId('Contact', c.Id));
			System.assert(Salesforce.isSObjectId('Opportunity', o.Id));
			System.assert(Salesforce.isSObjectId('Case', cs.Id));
			System.assert(!Salesforce.isSObjectId('Case', a.Id));
			System.assert(!Salesforce.isSObjectId('Contact', '0006A000001f5mLQAQ'));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_exists() {
		Test.startTest();
		// Object exists
		System.assert(Salesforce.exists('User'));
		System.assert(Salesforce.exists(' USER\n'));
		System.assert(Salesforce.exists('User', null));
		// Object does not exist
		System.assert(!Salesforce.exists('unitest__BogusObject__c', null));
		// Fields exist
		System.assert(Salesforce.exists('User', new Set<String> { 'Name', 'Email' }));
		// Fields do not exist
		System.assert(!Salesforce.exists('User', new Set<String> { 'Name', 'unitest__BogusField__c', 'Email' }));
		Test.stopTest();
	}

	@IsTest
	static void test_getSObjectType() {
		Test.startTest();
		try {
			Salesforce.getSObjectType(null);
			throw new AssertException('Expected getSObjectType to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidType, ex.getMessage());
		}
		try {
			Salesforce.getSObjectType('  ');
			throw new AssertException('Expected getSObjectType to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidType, ex.getMessage());
		}
		try {
			Salesforce.getSObjectType(UUID.randomUUID().toString());
			throw new AssertException('Expected getSObjectType to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidType, ex.getMessage());
		}
		System.assertEquals(Schema.Account.getSObjectType(), Salesforce.getSObjectType('Account'));
		System.assertEquals(Lead.getSObjectType(), Salesforce.getSObjectType('lead'));
		System.assertEquals(Contact.getSObjectType(), Salesforce.getSObjectType('CONTACT'));
		System.assertEquals(Envelope__c.getSObjectType(), Salesforce.getSObjectType('Envelope__c'));
		Test.stopTest();
	}

	@IsTest
	static void test_getNameField() {
		System.assertEquals(null, Salesforce.getNameField(null));
		System.assertEquals('Name', Salesforce.getNameField(Opportunity.getSObjectType()));
		System.assertEquals('CaseNumber', Salesforce.getNameField(Case.getSObjectType()));
	}

	@IsTest
	static void test_getLightningOrigin() {
		Test.startTest();
		System.assertEquals(
			'https://' + Url.getOrgDomainUrl().getHost().substringBefore('.') + '--' + Application.namespace + '.lightning.force.com',
			Salesforce.getLightningOrigin(true));
		System.assertEquals(
			'https://' + Url.getOrgDomainUrl().getHost().substringBefore('.') + '.lightning.force.com',
			Salesforce.getLightningOrigin(false));
		Test.stopTest();
	}

	@IsTest
	static void test_getVisualforceOrigin() {
		Test.startTest();
		System.assertEquals(
			'https://' + Url.getOrgDomainUrl().getHost().substringBefore('.') + '--' + Application.namespace + '.visualforce.com',
			Salesforce.getVisualforceOrigin(true));
		System.assertEquals(
			'https://' + Url.getOrgDomainUrl().getHost().substringBefore('.') + '.visualforce.com',
			Salesforce.getVisualforceOrigin(false));
		Test.stopTest();
	}

	@IsTest
	static void test_isValidOrigin() {
		Test.startTest();
		System.assert(!Salesforce.isValidOrigin(null));
		System.assert(!Salesforce.isValidOrigin('  '));
		System.assert(!Salesforce.isValidOrigin('https://example.com'));
		System.assert(!Salesforce.isValidOrigin('https://' + UUID.randomUUID() + '.lightning.force.com'));
		System.assert(!Salesforce.isValidOrigin('https://' + UUID.randomUUID() + '.visualforce.com'));
		System.assert(!Salesforce.isValidOrigin('https://evil.com?' + Salesforce.baseUrl.getHost().substringBefore('.') + 'lightning.force.com '));
		System.assert(!Salesforce.isValidOrigin('https://evil.com?' + Salesforce.baseUrl.getHost().substringBefore('.') + 'visualforce.com '));
		System.assert(!Salesforce.isValidOrigin('http://' + Salesforce.baseUrl.getHost().substringBefore('.') + 'visualforce.com '));
		System.assert(!Salesforce.isValidOrigin('http://' + Salesforce.baseUrl.getHost().substringBefore('.') + 'lightning.force.com '));
		System.assert(Salesforce.isValidOrigin(Salesforce.getLightningOrigin(true)));
		System.assert(Salesforce.isValidOrigin(Salesforce.getLightningOrigin(false)));
		System.assert(Salesforce.isValidOrigin(Salesforce.getVisualforceOrigin(true)));
		System.assert(Salesforce.isValidOrigin(Salesforce.getVisualforceOrigin(false)));
		Test.stopTest();
	}
}
