@IsTest
private class EnvelopeSettingsTest {

	static testMethod void test_getInstance() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			EnvelopeSettings ec1 = EnvelopeSettings.getInstance();
			EnvelopeSettings ec2 = EnvelopeSettings.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, ec1);
			System.assert(ec1 === ec2);
		}
	}

	static testMethod void test_getInstance_error() {
		System.runAs(TestUtils.createRestrictedUser()) {
			Test.startTest();
			EnvelopeSettings result = EnvelopeSettings.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.isValid);
			System.assertEquals(Label.CannotQueryObject + ' ' + Application.namespacePrefix + 'EnvelopeLocalization__c', result.errorMessage);
		}
	}

	static testMethod void test_mergeWith() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeSettings__c s = EnvelopeSettings__c.getOrgDefaults();
			s.HideTagButton__c = true;
			s.HideSendButton__c = false;
			s.HideEmailSubject__c = false;
			s.HideEmailMessage__c = false;
			s.HideRemindExpire__c = true;
			s.Chatter__c = 'Enabled';
			update s;

			Test.startTest();
			EnvelopeSettings ec = EnvelopeSettings.getInstance().mergeWith(new EnvelopeConfiguration.VisibilitySettings(
				true, // showTagButton
				false, // showSendButton
				null, // showEmailSubject
				true, // showEmailMessage
				null, // showRemindExpire
				null, // showChatter
				false)); // showAddAttachment
			Test.stopTest();

			System.assertNotEquals(null, ec);
			System.assert(ec.showTagButton);
			System.assert(!ec.showSendButton);
			System.assert(ec.allowEditEmailSubject);
			System.assert(ec.allowEditEmailMessage);
			System.assert(!ec.showRemindAndExpireSettings);
			System.assert(ec.isChatterEnabled);
			System.assert(!ec.showAddAttachment);
		}
	}

	static testMethod void test_getOptions() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeSettings__c settings = EnvelopeSettings__c.getOrgDefaults();
			settings.AddAnchorTags__c = true;
			settings.FetchDocuments__c = false;
			settings.UseNotificationDefaults__c = false;
			update settings;

			Test.startTest();
			Envelope.Options result = EnvelopeSettings.getOptions(true);
			System.assertNotEquals(null, result);
			System.assert(result.sendNow);
			System.assert(result.includeDefaultAnchorTabs);
			System.assert(!result.fetchDocuments);
			System.assert(!result.useAccountNotificationDefaults);

			result = EnvelopeSettings.getOptions(false);
			System.assertNotEquals(null, result);
			System.assert(!result.sendNow);
			System.assert(result.includeDefaultAnchorTabs);
			System.assert(!result.fetchDocuments);
			System.assert(!result.useAccountNotificationDefaults);
			Test.stopTest();
		}
	}
}
