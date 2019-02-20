@IsTest
private class AccountFeaturesTest {

	@IsTest
	static void test_getInstance() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			AccountFeatures af1 = AccountFeatures.getInstance();
			AccountFeatures af2 = AccountFeatures.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, af1);
			System.assert(af1 === af2);
		}
	}

	@IsTest
	static void test_getApiAccountFeatures_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
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
					} else if (accountSetting.name == 'allowServerTemplates') {
						result.put(AccountFeatures.FLAG_TEMPLATES, accountSetting.value == 'true');
					} else if (accountSetting.name == 'allowBulkSend') {
						result.put(AccountFeatures.FLAG_BULK_SENDING, accountSetting.value == 'true');
					}
				}
			}
			Test.stopTest();

			System.assertNotEquals(null, afs);
			System.assert(result.get(AccountFeatures.FLAG_MERGE_FIELDS));
			System.assert(result.get(AccountFeatures.FLAG_SHARED_CUSTOM_TABS));
			System.assert(result.get(AccountFeatures.FLAG_SAVING_CUSTOM_TABS));
			System.assert(result.get(AccountFeatures.FLAG_DATA_FIELD_REGEXES));
			System.assert(result.get(AccountFeatures.FLAG_DATA_FIELD_SIZES));
			System.assert(result.get(AccountFeatures.FLAG_TAB_TEXT_FORMATTING));
			System.assert(result.get(AccountFeatures.FLAG_TAB_DATA_LABELS));
			System.assert(result.get(AccountFeatures.FLAG_SIGNING_GROUPS));
			System.assert(result.get(AccountFeatures.FLAG_SMS_AUTHENTICATION));
			System.assert(result.get(AccountFeatures.FLAG_TEMPLATES));
			System.assert(result.get(AccountFeatures.FLAG_BULK_SENDING));
		}
	}

	@IsTest
	static void test_getApiAccountFeatures_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
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

	@IsTest
	static void test_resolveFeatures() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			AccountFeatures af = AccountFeatures.getInstance();

			Test.startTest();
			// Baseline config
			AccountSettings__c config0 = AccountSettings__c.getOrgDefaults();

			// Force check API, update config
			Integer features1 = af.resolveFeatures(0, Datetime.now().addDays(-2), 1);
			AccountSettings__c config1 = AccountSettings__c.getOrgDefaults();

			// Read from config, no update
			Integer features2 = af.resolveFeatures(3, Datetime.now().addMinutes(-10), 60);
			AccountSettings__c config2 = AccountSettings__c.getOrgDefaults();
			Test.stopTest();

			System.assertEquals(0, config0.Features__c);
			System.assertEquals(null, config0.FeaturesLastChecked__c);
			System.assertEquals(features1, Integer.valueOf(config1.Features__c));
			System.assertNotEquals(null, config1.FeaturesLastChecked__c);
			System.assertEquals(Datetime.now().dayOfYear(), config1.FeaturesLastChecked__c.dayOfYear());
			System.assertEquals(3, features2);
			System.assertEquals(config1.Features__c, config2.Features__c);
			System.assertEquals(config1.FeaturesLastChecked__c, config2.FeaturesLastChecked__c);
		}
	}

	@IsTest
	static void test_getFlags() {
		AccountFeatures.ApiAccountFeature f1 = new AccountFeatures.ApiAccountFeature();
		f1.name = 'dataFieldRegexEnabled';
		f1.value = 'true';
		AccountFeatures.ApiAccountFeature f2 = new AccountFeatures.ApiAccountFeature();
		f2.name = 'tabTextFormattingEnabled';
		f2.value = 'true';
		AccountFeatures.ApiAccountFeature f3 = new AccountFeatures.ApiAccountFeature();
		f3.name = 'tabDataLabelEnabled';
		f3.value = 'true';
		AccountFeatures.ApiAccountFeatures af = new AccountFeatures.ApiAccountFeatures();
		af.accountSettings = new List<AccountFeatures.ApiAccountFeature> { f1, f2, f3 };

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
		System.assertNotEquals(AccountFeatures.FLAG_TEMPLATES, features & AccountFeatures.FLAG_TEMPLATES);
		System.assertNotEquals(AccountFeatures.FLAG_BULK_SENDING, features & AccountFeatures.FLAG_BULK_SENDING);
	}
}
