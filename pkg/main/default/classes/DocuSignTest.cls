@IsTest(IsParallel = true)
private class DocuSignTest {

	@IsTest
	static void test_trialPlanId() {
		System.assertEquals(UUID.parse([
			SELECT TrialPlanId__c
			FROM Environment__mdt
			WHERE DeveloperName = 'Production'
			LIMIT 1
		].TrialPlanId__c), DocuSign.TRIAL_PLAN_ID);
	}

	@IsTest
	static void test_isValidHost() {
		System.assert(DocuSign.isValidHost('account.docusign.com'));
		System.assert(DocuSign.isValidHost('account-d.docusign.com'));
		System.assert(DocuSign.isValidHost('account-s.docusign.com'));
		System.assert(DocuSign.isValidHost('www.docusign.net'));
		System.assert(DocuSign.isValidHost('na2.docusign.net'));
		System.assert(DocuSign.isValidHost('na3.docusign.net'));
		System.assert(DocuSign.isValidHost('eu.docusign.net'));
		System.assert(DocuSign.isValidHost('au.docusign.net'));
		System.assert(DocuSign.isValidHost('ca.docusign.net'));
		System.assert(DocuSign.isValidHost('demo.docusign.net'));
		System.assert(DocuSign.isValidHost('stage.docusign.net'));
		System.assert(DocuSign.isValidHost('other.docusignhq.com'));
		System.assert(DocuSign.isValidHost('api-hqtest3.dev.docusign.net'));
		System.assert(DocuSign.isValidHost('something.springcm.com'));
		System.assert(!DocuSign.isValidHost(null));
		System.assert(!DocuSign.isValidHost(''));
		System.assert(!DocuSign.isValidHost(' '));
		System.assert(!DocuSign.isValidHost('example.com'));
		System.assert(!DocuSign.isValidHost('evil-docusign.net'));
		System.assert(!DocuSign.isValidHost('evil-docusign.com'));
		System.assert(!DocuSign.isValidHost('evil-docusignhq.com'));
		System.assert(!DocuSign.isValidHost('evil-springcm.com'));
	}

	@IsTest
	static void test_isValidUrl() {
		System.assert(DocuSign.isValidUrl(new Url('https://unit.test.docusign.net/test?a=1234')));
		System.assert(!DocuSign.isValidUrl(null));
		System.assert(!DocuSign.isValidUrl(new Url('http://www.docusign.net/')));
		System.assert(!DocuSign.isValidUrl(new Url('https://some.evil.site?docusign.net')));
	}

	@IsTest
	static void test_getEnvironment_host() {
		System.assertEquals(DocuSign.Environment.Invalid, DocuSign.getEnvironment((String)null));
		System.assertEquals(DocuSign.Environment.Invalid, DocuSign.getEnvironment(''));
		System.assertEquals(DocuSign.Environment.Invalid, DocuSign.getEnvironment('\t'));
		System.assertEquals(DocuSign.Environment.Invalid, DocuSign.getEnvironment('evil.com'));
		System.assertEquals(DocuSign.Environment.Invalid, DocuSign.getEnvironment('evil-docusign.net'));
		System.assertEquals(DocuSign.Environment.Production, DocuSign.getEnvironment('account.docusign.com'));
		System.assertEquals(DocuSign.Environment.Demo, DocuSign.getEnvironment('account-d.docusign.com'));
		System.assertEquals(DocuSign.Environment.Stage, DocuSign.getEnvironment('account-s.docusign.com'));
		System.assertEquals(DocuSign.Environment.HQTEST0, DocuSign.getEnvironment('account-hqtest0.dev.docusign.net'));
		System.assertEquals(DocuSign.Environment.HQTEST1, DocuSign.getEnvironment('account-hqtest1.dev.docusign.net'));
		System.assertEquals(DocuSign.Environment.HQTEST2, DocuSign.getEnvironment('account-hqtest2.dev.docusign.net'));
		System.assertEquals(DocuSign.Environment.HQTEST3, DocuSign.getEnvironment('account-hqtest3.dev.docusign.net'));
		System.assertEquals(DocuSign.Environment.Other, DocuSign.getEnvironment('other.docusignhq.com'));
	}

	@IsTest
	static void test_getEnvironment_url() {
		System.assertEquals(DocuSign.Environment.Invalid, DocuSign.getEnvironment((Url)null));
		System.assertEquals(DocuSign.Environment.Invalid, DocuSign.getEnvironment(new Url('https://evil.com')));
		System.assertEquals(DocuSign.Environment.Invalid, DocuSign.getEnvironment(new Url('http://evil.com/account.docusign.com')));
		System.assertEquals(DocuSign.Environment.Invalid, DocuSign.getEnvironment(new Url('https://account.evil-docusign.net')));
		System.assertEquals(DocuSign.Environment.Production, DocuSign.getEnvironment(new Url('https://account.docusign.com/oauth/token')));
		System.assertEquals(DocuSign.Environment.Demo, DocuSign.getEnvironment(new Url('https://account-d.docusign.com')));
		System.assertEquals(DocuSign.Environment.Stage, DocuSign.getEnvironment(new Url('https://account-s.docusign.com')));
		System.assertEquals(DocuSign.Environment.HQTEST0, DocuSign.getEnvironment(new Url('https://account-hqtest0.dev.docusign.net/')));
		System.assertEquals(DocuSign.Environment.HQTEST1, DocuSign.getEnvironment(new Url('https://account-hqtest1.dev.docusign.net/')));
		System.assertEquals(DocuSign.Environment.HQTEST2, DocuSign.getEnvironment(new Url('https://account-hqtest2.dev.docusign.net/')));
		System.assertEquals(DocuSign.Environment.HQTEST3, DocuSign.getEnvironment(new Url('https://account-hqtest3.dev.docusign.net/')));
		System.assertEquals(DocuSign.Environment.Other, DocuSign.getEnvironment(new Url('https://account-x.docusign.com')));
	}

	@IsTest
	static void test_parseEnvironment() {
		System.assertEquals(DocuSign.Environment.Invalid, DocuSign.parseEnvironment(null));
		System.assertEquals(DocuSign.Environment.Invalid, DocuSign.parseEnvironment(''));
		System.assertEquals(DocuSign.Environment.Invalid, DocuSign.parseEnvironment('  \n'));
		System.assertEquals(DocuSign.Environment.Invalid, DocuSign.parseEnvironment('blah'));
		System.assertEquals(DocuSign.Environment.Production, DocuSign.parseEnvironment('PROD'));
		System.assertEquals(DocuSign.Environment.Production, DocuSign.parseEnvironment('prod'));
		System.assertEquals(DocuSign.Environment.Production, DocuSign.parseEnvironment('Production'));
		System.assertEquals(DocuSign.Environment.Demo, DocuSign.parseEnvironment('demo'));
		System.assertEquals(DocuSign.Environment.Stage, DocuSign.parseEnvironment('stage'));
		System.assertEquals(DocuSign.Environment.QA, DocuSign.parseEnvironment('qA'));
		System.assertEquals(DocuSign.Environment.HQTEST0, DocuSign.parseEnvironment('hqtest0'));
		System.assertEquals(DocuSign.Environment.HQTEST1, DocuSign.parseEnvironment('hqtest1'));
		System.assertEquals(DocuSign.Environment.HQTEST2, DocuSign.parseEnvironment('hqtest2'));
		System.assertEquals(DocuSign.Environment.HQTEST3, DocuSign.parseEnvironment('hqtest3'));
		System.assertEquals(DocuSign.Environment.Other, DocuSign.parseEnvironment('other'));

	}

	@IsTest
	static void test_isValidEnvironment() {
		System.assert(!DocuSign.isValidEnvironment(null, null));
		System.assert(!DocuSign.isValidEnvironment(DocuSign.Environment.Invalid, null));
		System.assert(!DocuSign.isValidEnvironment(DocuSign.Environment.Other, null));
		System.assert(DocuSign.isValidEnvironment(DocuSign.Environment.Other, new Url('https://other.docusign.com')));
		System.assert(DocuSign.isValidEnvironment(null, new Url('https://other.docusign.com')));
		System.assert(DocuSign.isValidEnvironment(DocuSign.Environment.Production, new Url('https://other.docusign.com')));
		System.assert(DocuSign.isValidEnvironment(DocuSign.Environment.Production, null));
		System.assert(DocuSign.isValidEnvironment(DocuSign.Environment.Demo, null));
		System.assert(DocuSign.isValidEnvironment(DocuSign.Environment.Stage, null));
		System.assert(DocuSign.isValidEnvironment(DocuSign.Environment.QA, null));
		System.assert(DocuSign.isValidEnvironment(DocuSign.Environment.HQTEST0, null));
		System.assert(DocuSign.isValidEnvironment(DocuSign.Environment.HQTEST1, null));
		System.assert(DocuSign.isValidEnvironment(DocuSign.Environment.HQTEST2, null));
		System.assert(DocuSign.isValidEnvironment(DocuSign.Environment.HQTEST3, null));
	}
}
