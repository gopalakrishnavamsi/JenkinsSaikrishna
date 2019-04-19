@IsTest
private class AccountFeaturesTest {

	@IsTest
	static void test_getInstance_success() {
		DocuSignAPIMock.success();
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
	static void test_getInstance_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			AccountFeatures result = AccountFeatures.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.mergeFields);
			System.assert(!result.sharedCustomTabs);
			System.assert(!result.savingCustomTabs);
			System.assert(!result.dataFieldRegexes);
			System.assert(!result.dataFieldSizes);
			System.assert(!result.tabTextFormatting);
			System.assert(!result.tabDataLabels);
			System.assert(!result.signingGroups);
			System.assert(!result.smsAuthentication);
			System.assert(!result.templates);
			System.assert(!result.bulkSending);
		}
	}

	private static Boolean isSet(final Integer features, final Integer flag) {
		return (features & flag) == flag;
	}

	@IsTest
	static void test_SettingsAPI_getSettings_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Integer result = new AccountFeatures.SettingsAPI(
				new Url('https://unit.test.docusign.net'),
				UUID.randomUUID())
				.getSettings();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(isSet(result, AccountFeatures.FLAG_MERGE_FIELDS));
			System.assert(isSet(result, AccountFeatures.FLAG_SHARED_CUSTOM_TABS));
			System.assert(isSet(result, AccountFeatures.FLAG_SAVING_CUSTOM_TABS));
			System.assert(isSet(result, AccountFeatures.FLAG_DATA_FIELD_REGEXES));
			System.assert(isSet(result, AccountFeatures.FLAG_DATA_FIELD_SIZES));
			System.assert(isSet(result, AccountFeatures.FLAG_TAB_TEXT_FORMATTING));
			System.assert(isSet(result, AccountFeatures.FLAG_TAB_DATA_LABELS));
			System.assert(isSet(result, AccountFeatures.FLAG_SIGNING_GROUPS));
			System.assert(isSet(result, AccountFeatures.FLAG_SMS_AUTHENTICATION));
			System.assert(isSet(result, AccountFeatures.FLAG_TEMPLATES));
			System.assert(isSet(result, AccountFeatures.FLAG_BULK_SENDING));
		}
	}

	@IsTest
	static void test_SettingsAPI_getSettings_failure() {
		DocuSignAPIMock.failure();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				new AccountFeatures.SettingsAPI(
					new Url('https://unit.test.docusign.net'),
					UUID.randomUUID())
					.getSettings();
				throw new AssertException('Expected getApiAccountFeatures to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resolveFeatures() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			// Baseline config
			AccountSettings__c config0 = AccountSettings__c.getOrgDefaults();

			// Force check API, update config
			Integer features1 = AccountFeatures.resolveFeatures(0, Datetime.now().addDays(-2), 1);

			// Read from config, no update
			Integer features2 = AccountFeatures.resolveFeatures(3, Datetime.now().addMinutes(-10), 60);
			Test.stopTest();

			AccountSettings__c config1 = AccountSettings__c.getOrgDefaults();
			AccountSettings__c config2 = AccountSettings__c.getOrgDefaults();

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
}
