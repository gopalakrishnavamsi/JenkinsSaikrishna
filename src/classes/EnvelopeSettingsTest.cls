@IsTest
private class EnvelopeSettingsTest {

	@IsTest
	static void test_getInstance() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			EnvelopeSettings ec1 = EnvelopeSettings.getInstance();
			EnvelopeSettings ec2 = EnvelopeSettings.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, ec1);
			System.assert(ec1 === ec2);
			System.assertEquals(Localization.isEmailLocalizationEnabled(), ec1.allowRecipientLanguageSelection);
			System.assert(!ec1.isChatterEnabled);
			System.assert(!ec1.isChatterAlwaysOn);
			System.assert(!ec1.showChatter);
		}
	}

	@IsTest
	static void test_getInstance_error() {
		System.runAs(TestUtils.createRestrictedUser()) {
			Test.startTest();
			EnvelopeSettings result = EnvelopeSettings.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!result.isValid);
			System.assertEquals(Label.CannotQueryObject + ' ' + Application.namespacePrefix + 'EnvelopeLocalization__c', result.errorMessage);
		}
	}

	@IsTest
	static void test_mergeWith() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			EnvelopeSettings__c s = EnvelopeSettings__c.getOrgDefaults();
			s.HideTagButton__c = true;
			s.HideSendButton__c = false;
			s.HideEmailSubject__c = false;
			s.HideEmailMessage__c = false;
			s.HideRemindExpire__c = true;
			s.AllowSequentialSignNow__c = true;
			s.Chatter__c = 'EnabledDefaultOn';
			update s;

			Test.startTest();
			EnvelopeSettings ec = EnvelopeSettings.getInstance().mergeWith(new EnvelopeConfiguration.VisibilitySettings(
				true, // showTagButton
				false, // showSendButton
				null, // showEmailSubject
				true, // showEmailMessage
				null, // showRemindExpire
				null, // showChatter
				false)); // showAddFile
			Test.stopTest();

			System.assertNotEquals(null, ec);
			System.assert(ec.showTagButton);
			System.assert(!ec.showSendButton);
			System.assert(ec.allowEditEmailSubject);
			System.assert(ec.allowEditEmailMessage);
			System.assert(!ec.showRemindAndExpireSettings);
			System.assert(ec.allowSequentialSignNow);
			if (Salesforce.isChatterEnabled) {
				System.assert(ec.isChatterEnabled);
				System.assert(ec.showChatter);
			}
			System.assert(!ec.showAddFile);
		}
	}

	@IsTest
	static void test_getOptions() {
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

	@IsTest
	static void test_getChatterSetting() {
		Test.startTest();
		if (!Salesforce.isChatterEnabled) {
			System.assertEquals(EnvelopeSettings.CHATTER_DISABLED, EnvelopeSettings.getChatterSetting(true, true, true));
			System.assertEquals(EnvelopeSettings.CHATTER_DISABLED, EnvelopeSettings.getChatterSetting(false, true, true));
		} else {
			System.assertEquals(EnvelopeSettings.CHATTER_DISABLED, EnvelopeSettings.getChatterSetting(false, true, true));
			System.assertEquals(EnvelopeSettings.CHATTER_ENABLED_ALWAYS_ON, EnvelopeSettings.getChatterSetting(true, true, true));
			System.assertEquals(EnvelopeSettings.CHATTER_ENABLED_ALWAYS_ON, EnvelopeSettings.getChatterSetting(true, false, true));
			System.assertEquals(EnvelopeSettings.CHATTER_ENABLED_DEFAULT_ON, EnvelopeSettings.getChatterSetting(true, true, false));
			System.assertEquals(EnvelopeSettings.CHATTER_ENABLED_DEFAULT_OFF, EnvelopeSettings.getChatterSetting(true, false, false));
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getCanonicalChatterSetting() {
		Test.startTest();
		System.assertEquals(EnvelopeSettings.CHATTER_DISABLED, EnvelopeSettings.getCanonicalChatterSetting(null));
		System.assertEquals(EnvelopeSettings.CHATTER_DISABLED, EnvelopeSettings.getCanonicalChatterSetting(''));
		System.assertEquals(EnvelopeSettings.CHATTER_DISABLED, EnvelopeSettings.getCanonicalChatterSetting('\t '));
		System.assertEquals(EnvelopeSettings.CHATTER_DISABLED, EnvelopeSettings.getCanonicalChatterSetting('invalid'));
		if (!Salesforce.isChatterEnabled) {
			System.assertEquals(EnvelopeSettings.CHATTER_DISABLED, EnvelopeSettings.getCanonicalChatterSetting(EnvelopeSettings.CHATTER_DISABLED));
			System.assertEquals(EnvelopeSettings.CHATTER_DISABLED, EnvelopeSettings.getCanonicalChatterSetting(EnvelopeSettings.CHATTER_ENABLED_DEFAULT_OFF));
			System.assertEquals(EnvelopeSettings.CHATTER_DISABLED, EnvelopeSettings.getCanonicalChatterSetting(EnvelopeSettings.CHATTER_ENABLED_DEFAULT_ON));
			System.assertEquals(EnvelopeSettings.CHATTER_DISABLED, EnvelopeSettings.getCanonicalChatterSetting(EnvelopeSettings.CHATTER_ENABLED_ALWAYS_ON));
		} else {
			System.assertEquals(EnvelopeSettings.CHATTER_DISABLED, EnvelopeSettings.getCanonicalChatterSetting('DISABLED'));
			System.assertEquals(EnvelopeSettings.CHATTER_ENABLED_DEFAULT_OFF, EnvelopeSettings.getCanonicalChatterSetting(' Enableddefaultoff\n'));
			System.assertEquals(EnvelopeSettings.CHATTER_ENABLED_DEFAULT_ON, EnvelopeSettings.getCanonicalChatterSetting('enableddefaulton'));
			System.assertEquals(EnvelopeSettings.CHATTER_ENABLED_ALWAYS_ON, EnvelopeSettings.getCanonicalChatterSetting('EnabledAlwaysOn'));
		}
		Test.stopTest();
	}

	@IsTest
	static void test_save() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();

			EnvelopeSettings s = new EnvelopeSettings(
				true,
				false,
				false,
				true,
				false,
				false,
				new List<Recipient.EmailSettings> {
					new Recipient.EmailSettings(Localization.ES, 'whatever', 'es subject', 'es message'),
					new Recipient.EmailSettings(Localization.ZH_CN, 'whatever', 'zh-CN subject', 'zh-CN message')
				},
				true,
				true,
				EnvelopeSettings.CHATTER_ENABLED_DEFAULT_OFF,
				new ChatterEvents(true, false, true, false, true, false, true, false, true, false),
				new Localization.ChatterText('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'),
				new List<Recipient.Role> {
					new Recipient.Role('New Role 1', 10),
					new Recipient.Role('New Role 2', -1)
				},
				null);

			Test.startTest();
			EnvelopeSettings result = EnvelopeSettings.save(s);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!(result === s));
			System.assert(result.showTagButton);
			System.assert(!result.showSendButton);
			System.assert(!result.showAddFile);
			System.assert(result.showRemindAndExpireSettings);
			System.assert(!result.allowEditEmailSubject);
			System.assert(!result.allowEditEmailMessage);
			System.assertNotEquals(null, result.emailLocalizations);
			System.assertEquals(3, result.emailLocalizations.size());
			System.assert(result.isSmsEnabled);
			System.assert(result.allowSequentialSignNow);
			System.assertEquals(EnvelopeSettings.CHATTER_ENABLED_DEFAULT_OFF, result.chatterSetting);
			System.assertNotEquals(null, result.chatterPostEvents);
			System.assert(result.chatterPostEvents.postEnvelopeSent);
			System.assert(!result.chatterPostEvents.postEnvelopeDelivered);
			System.assert(result.chatterPostEvents.postEnvelopeCompleted);
			System.assert(!result.chatterPostEvents.postEnvelopeDeclined);
			System.assert(result.chatterPostEvents.postEnvelopeVoided);
			System.assert(!result.chatterPostEvents.postRecipientSent);
			System.assert(result.chatterPostEvents.postRecipientDelivered);
			System.assert(!result.chatterPostEvents.postRecipientCompleted);
			System.assert(result.chatterPostEvents.postRecipientSigned);
			System.assert(!result.chatterPostEvents.postRecipientDeclined);
			System.assertNotEquals(null, result.chatterLocalization);
			System.assertEquals('a', result.chatterLocalization.envelopeSent);
			System.assertEquals('b', result.chatterLocalization.envelopeDelivered);
			System.assertEquals('c', result.chatterLocalization.envelopeCompleted);
			System.assertEquals('d', result.chatterLocalization.envelopeDeclined);
			System.assertEquals('e', result.chatterLocalization.envelopeVoided);
			System.assertEquals('f', result.chatterLocalization.recipientSent);
			System.assertEquals('g', result.chatterLocalization.recipientDelivered);
			System.assertEquals('h', result.chatterLocalization.recipientCompleted);
			System.assertEquals('i', result.chatterLocalization.recipientSigned);
			System.assertEquals('j', result.chatterLocalization.recipientDeclined);
			System.assertNotEquals(null, result.defaultRoles);
			System.assertEquals(2, result.defaultRoles.size());
			System.assertEquals('New Role 1', result.defaultRoles[0].name);
			System.assertEquals(1, result.defaultRoles[0].value);
			System.assertEquals('New Role 2', result.defaultRoles[1].name);
			System.assertEquals(2, result.defaultRoles[1].value);
			System.assertEquals(null, result.errorMessage);

		}
	}
}
