@IsTest
private class SalesforceTest {

	@IsTest
	static void test_namespace() {
		System.assertEquals([SELECT NamespacePrefix FROM Organization LIMIT 1].NamespacePrefix, Salesforce.namespace);
	}

	@IsTest
	static void test_instance() {
		System.assertEquals([SELECT InstanceName FROM Organization LIMIT 1].InstanceName.toLowerCase(), Salesforce.instance);
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
		System.assertEquals([SELECT OrganizationType FROM Organization LIMIT 1].OrganizationType, Salesforce.edition);
	}

	@IsTest
	static void test_isSandbox() {
		System.assertEquals([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox, Salesforce.isSandbox);
	}

	@IsTest
	static void test_isApiSupported() {
		String orgType = null;
		List<Organization> orgs = [SELECT Id, OrganizationType FROM Organization LIMIT 1];
		if (Collection.isNotEmpty(orgs)) {
			orgType = orgs[0].OrganizationType;
		}
		System.assertEquals((orgType == 'Professional Edition' || orgType == 'Developer Edition' || orgType == 'Enterprise Edition' || orgType == 'Unlimited Edition'),
			Salesforce.isApiSupported);
	}

	@IsTest
	static void test_isFlsSupported() {
		String orgType = null;
		List<Organization> orgs = [SELECT Id, OrganizationType FROM Organization LIMIT 1];
		if (Collection.isNotEmpty(orgs)) {
			orgType = orgs[0].OrganizationType;
		}
		System.assertEquals((orgType == 'Developer Edition' || orgType == 'Enterprise Edition' || orgType == 'Unlimited Edition'),
			Salesforce.isFlsSupported);
	}

	@IsTest
	static void test_oauthUrl() {
		System.assertEquals(Salesforce.baseUrl.toExternalForm() + '/services/oauth2/authorize',
			Salesforce.oauthUrl.toExternalForm());
	}

	@IsTest
	static void test_isCommunitySite() {
		System.assertEquals(Site.getSiteType() == 'ChatterNetwork', Salesforce.isCommunitySite);
	}

	@IsTest
	static void test_getSObjectType() {
		String testInput1 = null;
		String testInput2 = '  ';
		String testInput3 = UUID.randomUUID().toString();

		Test.startTest();
		try {
			Salesforce.getSObjectType(testInput1);
			throw new AssertException('Expected getSObjectType to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(
				String.format(
					Label.InvalidSObjectType_1,
					new List<String> {
						testInput1
					}
				),
				ex.getMessage()
			);
		}
		try {
			Salesforce.getSObjectType(testInput2);
			throw new AssertException('Expected getSObjectType to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(
				String.format(
					Label.InvalidSObjectType_1,
					new List<String> {
						testInput2
					}
				),
				ex.getMessage()
			);
		}
		try {
			Salesforce.getSObjectType(testInput3);
			throw new AssertException('Expected getSObjectType to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(
				String.format(
					Label.InvalidSObjectType_1,
					new List<String> {
						testInput3
					}
				),
				ex.getMessage()
			);
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
	static void test_getOrigin() {
		String myDomain = Salesforce.baseUrl.getHost().substringBefore('.');
		String instance = Salesforce.instance;
		String namespace = Salesforce.namespace;
		String rootDomain = 'salesforce.com';

		Test.startTest();
		System.assertEquals('https://' + myDomain + '.' + rootDomain,
			Salesforce.getOrigin(myDomain, null, null, rootDomain));
		System.assertEquals('https://' + myDomain + '--' + namespace + '.' + rootDomain,
			Salesforce.getOrigin(myDomain, namespace, null, rootDomain));
		System.assertEquals('https://' + myDomain + '--' + namespace + '.' + instance + '.' + rootDomain,
			Salesforce.getOrigin(myDomain, namespace, instance, rootDomain));
		System.assertEquals('https://' + myDomain + '.' + instance + '.' + rootDomain,
			Salesforce.getOrigin(myDomain, null, instance, rootDomain));
		Test.stopTest();
	}

	static String vfOrigin1() {
		return 'https://'
			+ Url.getOrgDomainUrl().getHost().substringBefore('.')
			+ '--' + Application.namespace
			+ '.visualforce.com';
	}

	static String vfOrigin2() {
		return 'https://'
			+ Url.getOrgDomainUrl().getHost().substringBefore('.')
			+ '--' + Application.namespace
			+ '.' + Salesforce.instance
			+ '.visual.force.com';
	}

	@IsTest
	static void test_getVisualforceOrigins() {
		Test.startTest();
		List<String> result = Salesforce.getVisualforceOrigins();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(2, result.size());
		System.assert(result.contains(vfOrigin1()), 'Origin not found: ' + vfOrigin1());
		System.assert(result.contains(vfOrigin2()), 'Origin not found: ' + vfOrigin2());
	}

	static String lexOrigin1() {
		return 'https://'
			+ Url.getOrgDomainUrl().getHost().substringBefore('.')
//			+ '--' + Application.namespace
			+ '.lightning.force.com';
	}

	static String lexOrigin2() {
		return 'https://'
			+ Url.getOrgDomainUrl().getHost().substringBefore('.')
//			+ '--' + Application.namespace
			+ '.' + Salesforce.instance
			+ '.lightning.force.com';
	}

	@IsTest
	static void test_getLightningOrigins() {
		Test.startTest();
		List<String> result = Salesforce.getLightningOrigins();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(2, result.size());
		System.assert(result.contains(lexOrigin1()), 'Origin not found: ' + lexOrigin1());
		System.assert(result.contains(lexOrigin2()), 'Origin not found: ' + lexOrigin2());
	}

	@IsTest
	static void test_isValidCommunityURL() {
		List<Profile> profileData = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];
		if (Schema.getGlobalDescribe().containsKey('Network') && Collection.isNotEmpty(profileData)) {
			Schema.Account acc = TestUtils.createAccount();
			Contact con = TestUtils.createContact(acc.Id);
			User user = new User (
				ContactId = con.Id,
				FirstName = 'Unit',
				LastName = 'Test',
				Username = UUID.randomUUID().toString() + '@unit.test',
				Email = UUID.randomUUID().toString() + '@unit.test',
				Alias = 'test',
				TimeZoneSidKey = 'America/Los_Angeles',
				LocaleSidKey = 'en_US',
				EmailEncodingKey = 'ISO-8859-1',
				ProfileId = profileData[0].Id,
				LanguageLocaleKey = 'en_US');
			insert user;
			System.runAs(user) {
				Test.startTest();
				Id user_id = user.Id;
				List<SObject> networkMemberData = Database.query('SELECT Network.Id FROM NetworkMember WHERE MemberId =: user_id LIMIT 1');
				if (Collection.isNotEmpty(networkMemberData)) {
					System.assertEquals(true, Salesforce.isValidTarget(Network.getLoginUrl((Id)networkMemberData[0].getSObject('Network').get('Id')).removeEndIgnoreCase('/login')));
					System.assertNotEquals(null, Salesforce.getCommunityOrigins());
				}
				Test.stopTest();
			}
		}
	}

	@IsTest
	static void test_isValidTarget() {
		Test.startTest();
		System.assert(!Salesforce.isValidTarget(null));
		System.assert(!Salesforce.isValidTarget('  '));
		System.assert(!Salesforce.isValidTarget('https://example.com'));
		System.assert(!Salesforce.isValidTarget('https://' + UUID.randomUUID() + '.lightning.force.com'));
		System.assert(!Salesforce.isValidTarget('https://' + UUID.randomUUID() + '.visualforce.com'));
		System.assert(!Salesforce.isValidTarget('https://evil.com?' + Salesforce.baseUrl.getHost().substringBefore('.') + 'lightning.force.com '));
		System.assert(!Salesforce.isValidTarget('https://evil.com?' + Salesforce.baseUrl.getHost().substringBefore('.') + 'visualforce.com '));
		System.assert(!Salesforce.isValidTarget('http://' + Salesforce.baseUrl.getHost().substringBefore('.') + 'visualforce.com '));
		System.assert(!Salesforce.isValidTarget('http://' + Salesforce.baseUrl.getHost().substringBefore('.') + 'lightning.force.com '));
		System.assert(Salesforce.isValidTarget(lexOrigin1()), 'Target not valid: ' + lexOrigin1());
		System.assert(Salesforce.isValidTarget(lexOrigin2()), 'Target not valid: ' + lexOrigin2());
		System.assert(Salesforce.isValidTarget(vfOrigin1()), 'Target not valid: ' + vfOrigin1());
		System.assert(Salesforce.isValidTarget(vfOrigin2()), 'Target not valid: ' + vfOrigin1());
		Test.stopTest();
	}

	@IsTest
	static void test_isValidSObjectTest() {
		Test.startTest();
		System.assert(Salesforce.isValidSObject('Account'));
		System.assert(Salesforce.isValidSObject('USER'));
		System.assert(Salesforce.isValidSObject(Application.namespacePrefix + 'envelope__c'));
		System.assert(!Salesforce.isValidSObject('Parent'));
		Test.stopTest();
	}

	@IsTest
	static void test_getParentSobjectType() {
		Test.startTest();
		System.assertEquals(Schema.Account.getSObjectType(), Salesforce.getParentSObjectType(Schema.Account.getSObjectType(), 'ParentId'));
		System.assertEquals(Schema.Account.getSObjectType(), Salesforce.getParentSObjectType(Schema.Account.getSObjectType(), 'MasterRecordId'));
		System.assertEquals(Schema.Case.getSObjectType(), Salesforce.getParentSObjectType(Schema.Case.getSObjectType(), 'ParentId'));
		System.assertEquals(Schema.User.getSObjectType(), Salesforce.getParentSObjectType(Schema.Case.getSObjectType(), 'OwnerID'));
		Test.stopTest();
	}

	@IsTest
	static void test_getNamespace() {
		Test.startTest();
		System.assertEquals('', Salesforce.getNamespace(null));
		System.assertEquals('', Salesforce.getNamespace(Opportunity.getSObjectType()));
		System.assertEquals(Application.namespace, Salesforce.getNamespace(Envelope__c.getSObjectType()));
		if (Salesforce.isValidSObject('SBQQ__Quote__c')) {
			System.assertEquals('SBQQ', Salesforce.getNamespace(Salesforce.getSObjectType('SBQQ__Quote__c')));
		}
		if (Salesforce.isValidSObject('blng__Invoice__c')) {
			System.assertEquals('blng', Salesforce.getNamespace(Salesforce.getSObjectType('blng__Invoice__c')));
		}
		Test.stopTest();
	}
}
