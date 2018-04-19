@IsTest
private class AccountFeaturesTest {

	static Integer DEFAULT_FLAGS = AccountFeatures.FLAG_MERGE_FIELDS
		| AccountFeatures.FLAG_SHARED_CUSTOM_TABS
		| AccountFeatures.FLAG_SAVING_CUSTOM_TABS
		| AccountFeatures.FLAG_DATA_FIELD_SIZES
		| AccountFeatures.FLAG_SIGNING_GROUPS
		| AccountFeatures.FLAG_SMS_AUTHENTICATION;

	static testMethod void test_getInstance() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			AccountFeatures af1 = AccountFeatures.getInstance();
			AccountFeatures af2 = AccountFeatures.getInstance();
			Test.stopTest();

			System.assert(af1 === af2);
			System.assertNotEquals(null, af1);
			System.assert(af1.mergeFields);
			System.assert(af1.sharedCustomTabs);
			System.assert(af1.savingCustomTabs);
			System.assert(!af1.dataFieldRegexes);
			System.assert(af1.dataFieldSizes);
			System.assert(!af1.tabTextFormatting);
			System.assert(!af1.tabDataLabels);
			System.assert(af1.signingGroups);
			System.assert(af1.smsAuthentication);
		}
	}

	static testMethod void test_getApiAccountFeatures_success() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			AccountFeatures client = AccountFeatures.getInstance();

			Test.startTest();
			AccountFeatures.ApiAccountFeatures afs = client.getApiAccountFeatures();
			Map<Integer, Boolean> result = new Map<Integer, Boolean>();
			if (afs != null && afs.accountSettings != null) {
				for (AccountFeatures.ApiAccountFeature accountSetting : afs.accountSettings) {
					if (accountSetting.name == 'allowMergeFields') {
						result.put(AccountFeatures.FLAG_MERGE_FIELDS, accountSetting.value == 'true');
					} else if (accountSetting.name == 'sharedCustomTabsEnabled') {
						result.put(AccountFeatures.FLAG_SHARED_CUSTOM_TABS, accountSetting.value == 'true');
					} else if (accountSetting.name == 'savingCustomTabsEnabled') {
						result.put(AccountFeatures.FLAG_SAVING_CUSTOM_TABS, accountSetting.value == 'true');
					} else if (accountSetting.name == 'dataFieldRegexEnabled') {
						result.put(AccountFeatures.FLAG_DATA_FIELD_REGEXES, accountSetting.value == 'true');
					} else if (accountSetting.name == 'dataFieldSizeEnabled') {
						result.put(AccountFeatures.FLAG_DATA_FIELD_SIZES, accountSetting.value == 'true');
					} else if (accountSetting.name == 'tabTextFormattingEnabled') {
						result.put(AccountFeatures.FLAG_TAB_TEXT_FORMATTING, accountSetting.value == 'true');
					} else if (accountSetting.name == 'allowSigningGroups') {
						result.put(AccountFeatures.FLAG_SIGNING_GROUPS, accountSetting.value == 'true');
					} else if (accountSetting.name == 'tabDataLabelEnabled') {
						result.put(AccountFeatures.FLAG_TAB_DATA_LABELS, accountSetting.value == 'true');
					} else if (accountSetting.name == 'enableSMSAuthentication') {
						result.put(AccountFeatures.FLAG_SMS_AUTHENTICATION, accountSetting.value == 'true');
					}
				}
			}
			Test.stopTest();

			System.assertNotEquals(null, afs);
			System.assert(result.get(AccountFeatures.FLAG_MERGE_FIELDS));
			System.assert(result.get(AccountFeatures.FLAG_SHARED_CUSTOM_TABS));
			System.assert(result.get(AccountFeatures.FLAG_SAVING_CUSTOM_TABS));
			System.assert(!result.get(AccountFeatures.FLAG_DATA_FIELD_REGEXES));
			System.assert(result.get(AccountFeatures.FLAG_DATA_FIELD_SIZES));
			System.assert(!result.get(AccountFeatures.FLAG_TAB_TEXT_FORMATTING));
			System.assert(!result.get(AccountFeatures.FLAG_TAB_DATA_LABELS));
			System.assert(result.get(AccountFeatures.FLAG_SIGNING_GROUPS));
			System.assert(result.get(AccountFeatures.FLAG_SMS_AUTHENTICATION));
		}
	}

	static testMethod void test_getApiAccountFeatures_failure() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.FailureMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			AccountFeatures client = AccountFeatures.getInstance();
			APIException ex;

			Test.startTest();
			try {
				client.getApiAccountFeatures();
				throw new AssertException('Expected getApiAccountFeatures to fail');
			} catch (APIException ex2) {
				ex = ex2;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(400, ex.error.code);
		}
	}

	static testMethod void test_resolveFeatures() {
		Test.setMock(HttpCalloutMock.class, new DocuSignAPITest.SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			AccountFeatures af = AccountFeatures.getInstance();

			Test.startTest();
			// Baseline config
			AccountSettings__c config0 = AccountSettings__c.getOrgDefaults();

			// Force check API, update config
			Integer features1 = af.resolveFeatures(0, DateTime.now().addDays(-2), 1);
			AccountSettings__c config1 = AccountSettings__c.getOrgDefaults();

			// Read from config, no update
			Integer features2 = af.resolveFeatures(3, DateTime.now().addMinutes(-10), 60);
			AccountSettings__c config2 = AccountSettings__c.getOrgDefaults();
			Test.stopTest();

			System.assertEquals(0, config0.Features__c);
			System.assertEquals(null, config0.FeaturesLastChecked__c);
			System.assertEquals(DEFAULT_FLAGS, features1);
			System.assertEquals(features1, Integer.valueOf(config1.Features__c));
			System.assertNotEquals(null, config1.FeaturesLastChecked__c);
			System.assertEquals(DateTime.now().dayOfYear(), config1.FeaturesLastChecked__c.dayOfYear());
			System.assertEquals(3, features2);
			System.assertEquals(config1.Features__c, config2.Features__c);
			System.assertEquals(config1.FeaturesLastChecked__c, config2.FeaturesLastChecked__c);
		}
	}

	static testMethod void test_getFlags() {
		AccountFeatures.APIAccountFeature f1 = new AccountFeatures.ApiAccountFeature();
		f1.name = 'dataFieldRegexEnabled';
		f1.value = 'true';
		AccountFeatures.APIAccountFeature f2 = new AccountFeatures.ApiAccountFeature();
		f2.name = 'tabTextFormattingEnabled';
		f2.value = 'true';
		AccountFeatures.APIAccountFeature f3 = new AccountFeatures.ApiAccountFeature();
		f3.name = 'tabDataLabelEnabled';
		f3.value = 'true';
		AccountFeatures.ApiAccountFeatures af = new AccountFeatures.ApiAccountFeatures();
		af.accountSettings = new List<AccountFeatures.APIAccountFeature> { f1, f2, f3 };

		Test.startTest();
		Integer features = AccountFeatures.getFlags(af);
		Test.stopTest();

		System.assertNotEquals(AccountFeatures.FLAG_MERGE_FIELDS, features & AccountFeatures.FLAG_MERGE_FIELDS);
		System.assertNotEquals(AccountFeatures.FLAG_SHARED_CUSTOM_TABS, features & AccountFeatures.FLAG_SHARED_CUSTOM_TABS);
		System.assertNotEquals(AccountFeatures.FLAG_SAVING_CUSTOM_TABS, features & AccountFeatures.FLAG_SAVING_CUSTOM_TABS);
		System.assertEquals(AccountFeatures.FLAG_DATA_FIELD_REGEXES, features & AccountFeatures.FLAG_DATA_FIELD_REGEXES);
		System.assertNotEquals(AccountFeatures.FLAG_DATA_FIELD_SIZES, features & AccountFeatures.FLAG_DATA_FIELD_SIZES);
		System.assertEquals(AccountFeatures.FLAG_TAB_TEXT_FORMATTING, features & AccountFeatures.FLAG_TAB_TEXT_FORMATTING);
		System.assertEquals(AccountFeatures.FLAG_TAB_DATA_LABELS, features & AccountFeatures.FLAG_TAB_DATA_LABELS);
		System.assertNotEquals(AccountFeatures.FLAG_SIGNING_GROUPS, features & AccountFeatures.FLAG_SIGNING_GROUPS);
		System.assertNotEquals(AccountFeatures.FLAG_SMS_AUTHENTICATION, features & AccountFeatures.FLAG_SMS_AUTHENTICATION);
	}
}
