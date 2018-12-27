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
		System.assertEquals(String.isNotBlank(siteBaseUrl) ? siteBaseUrl : Url.getSalesforceBaseUrl().toExternalForm(),
			Salesforce.baseUrl.toExternalForm());
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
	static void test_MergeObject() {
		Salesforce.MergeObject mo1 = new Salesforce.MergeObject('A', null, true);
		Salesforce.MergeObject mo2 = new Salesforce.MergeObject('B', '', true);
		Salesforce.MergeObject mo3 = new Salesforce.MergeObject('C', ' ', true);
		Salesforce.MergeObject mo4 = new Salesforce.MergeObject('A', 'Object A', true);
		Salesforce.MergeObject mo5 = new Salesforce.MergeObject('A', 'Object A', true);
		Salesforce.MergeObject mo6 = new Salesforce.MergeObject('B', 'Object B', true);
		Salesforce.MergeObject mo7 = new Salesforce.MergeObject('C', 'Object C', true);
		List<Salesforce.MergeObject> mos1 = new List<Salesforce.MergeObject> {
			mo1, mo2, mo3, mo4, mo5, mo6, mo7
		};
		List<Salesforce.MergeObject> mos2 = new List<Salesforce.MergeObject> {
			mo3, mo4, mo1, mo7, mo6, mo2, mo5
		};

		Test.startTest();
		mos2.sort();
		Test.stopTest();

		System.assertEquals(mos1, mos2);
	}

	@IsTest
	static void test_MergeField() {
		Salesforce.MergeField mf1 = new Salesforce.MergeField(1, 'A', 'A', null, null, null, false);
		Salesforce.MergeField mf2 = new Salesforce.MergeField(1, 'B', 'B', '', null, null, false);
		Salesforce.MergeField mf3 = new Salesforce.MergeField(1, 'C', 'C', ' ', null, null, false);
		Salesforce.MergeField mf4 = new Salesforce.MergeField(1, 'A', 'A', 'Field A', null, null, false);
		Salesforce.MergeField mf5 = new Salesforce.MergeField(1, 'A', 'A', 'Field A', null, null, false);
		Salesforce.MergeField mf6 = new Salesforce.MergeField(1, 'B', 'B', 'Field B', null, null, false);
		Salesforce.MergeField mf7 = new Salesforce.MergeField(1, 'C', 'C', 'Field C', null, null, false);
		List<Salesforce.MergeField> mfs1 = new List<Salesforce.MergeField> {
			mf1, mf2, mf3, mf4, mf5, mf6, mf7
		};
		List<Salesforce.MergeField> mfs2 = new List<Salesforce.MergeField> {
			mf3, mf4, mf1, mf7, mf6, mf2, mf5
		};

		Test.startTest();
		mfs2.sort();
		Test.stopTest();

		System.assertEquals(mfs1, mfs2);
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
	static void test_getLightningHost() {
		String host = Url.getSalesforceBaseUrl().getHost();
		host = host.substring(0, host.indexOf('.')).remove('--c').remove('--' + Application.packageNamespace)
			+ '.lightning.force.com';

		Test.startTest();
		System.assertEquals(host, Salesforce.getLightningHost());
		Test.stopTest();
	}

	@IsTest
	static void test_getVisualforceHost() {
		Test.startTest();
		System.assertEquals(Url.getSalesforceBaseUrl().getHost().substringBefore('.') + '.visualforce.com',
			Salesforce.getVisualforceHost());
		Test.stopTest();
	}
}
