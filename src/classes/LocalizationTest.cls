@IsTest
private class LocalizationTest {

	static Localization__mdt defaultLocalization(final String language) {
		List<Localization__mdt> locs = [
			SELECT EmailSubject__c, EmailMessage__c
			FROM Localization__mdt
			WHERE DeveloperName = :language

		];
		if (Collection.isNotEmpty(locs)) {
			return locs[0];
		} else {
			return new Localization__mdt();
		}
	}

	static testMethod void test_email_settings() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			List<Recipient.EmailSettings> localizationSettings = Localization.getEmailSettings();
			// By default localization settings should only contain english as a language setting
			System.assertEquals(1, localizationSettings.size());

			//updating english
			Localization.updateEmailSettings(new Recipient.EmailSettings('en', 'English', 'test subject en', ''));
			Recipient.EmailSettings enSetting = Localization.getEmailSettings('en');
			System.assertEquals('test subject en', enSetting.subject);

			//adding and verifying german has been added
			Localization.updateEmailSettings(new Recipient.EmailSettings('de', 'German', 'test subject de', ''));
			Recipient.EmailSettings deSetting = Localization.getEmailSettings('de');
			System.assertEquals('test subject de', deSetting.subject);

			//adding and verifying spanish has been added
			Localization.updateEmailSettings(new Recipient.EmailSettings('es', 'Spanish', 'test subject es', ''));
			Recipient.EmailSettings esSetting = Localization.getEmailSettings('es');
			System.assertEquals('test subject es', esSetting.subject);

			//adding and verifying french has been added
			Localization.updateEmailSettings(new Recipient.EmailSettings('fr', 'French', 'test subject fr', ''));
			Recipient.EmailSettings frSetting = Localization.getEmailSettings('fr');
			System.assertEquals('test subject fr', frSetting.subject);

			//adding and verifying italian has been added
			Localization.updateEmailSettings(new Recipient.EmailSettings('it', 'Italian', 'test subject it', ''));
			Recipient.EmailSettings itSetting = Localization.getEmailSettings('it');
			System.assertEquals('test subject it', itSetting.subject);

			//adding and verifying japanese has been added
			Localization.updateEmailSettings(new Recipient.EmailSettings('ja', 'Japanese', 'test subject ja', ''));
			Recipient.EmailSettings jaSetting = Localization.getEmailSettings('ja');
			System.assertEquals('test subject ja', jaSetting.subject);

			//adding and verifying korean has been added
			Localization.updateEmailSettings(new Recipient.EmailSettings('ko', 'Korean', 'test subject ko', ''));
			Recipient.EmailSettings koSetting = Localization.getEmailSettings('ko');
			System.assertEquals('test subject ko', koSetting.subject);

			//adding and verifying dutch has been added
			Localization.updateEmailSettings(new Recipient.EmailSettings('nl', 'Dutch', 'test subject nl', ''));
			Recipient.EmailSettings nlSetting = Localization.getEmailSettings('nl');
			System.assertEquals('test subject nl', nlSetting.subject);

			//adding and verifying portuguese brazilian has been added
			Localization.updateEmailSettings(new Recipient.EmailSettings('pt_BR', 'Portuguese-Brazil', 'test subject pt_BR', ''));
			Recipient.EmailSettings ptbrSetting = Localization.getEmailSettings('pt_BR');
			System.assertEquals('test subject pt_BR', ptbrSetting.subject);

			//adding and verifying russian has been added
			Localization.updateEmailSettings(new Recipient.EmailSettings('ru', 'Russian', 'test subject ru', ''));
			Recipient.EmailSettings ruSetting = Localization.getEmailSettings('ru');
			System.assertEquals('test subject ru', ruSetting.subject);

			//adding and verifying chinese traditional has been added
			Localization.updateEmailSettings(new Recipient.EmailSettings('zh_CN', 'Chinese-simplified', 'test subject zh_CN', ''));
			Recipient.EmailSettings zhCNSetting = Localization.getEmailSettings('zh_CN');
			System.assertEquals('test subject zh_CN', zhCNSetting.subject);

			localizationSettings = Localization.getEmailSettings();
			//verifying all languages have been added to the email settings
			System.assertEquals(11, localizationSettings.size());

			System.assertEquals(null, Localization.getEmailSettings('aa'));

			Boolean updateEmailSettingsLanguageCodeError = false;
			try {
				Localization.updateEmailSettings(new Recipient.EmailSettings('ab', '', '', ''));
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UnrecognizedLanguageCode, ex.getMessage());
			}

			//testing getDefaultSettings
			//english
			Recipient.EmailSettings defaultEn = Localization.getDefaultEmailSettings('en');
			System.assertEquals(defaultLocalization('en').EmailSubject__c, defaultEn.subject);
			//German
			Recipient.EmailSettings defaultDe = Localization.getDefaultEmailSettings('de');
			System.assertEquals(defaultLocalization('de').EmailSubject__c, defaultDe.subject);
			//Spanish
			Recipient.EmailSettings defaultEs = Localization.getDefaultEmailSettings('es');
			System.assertEquals(defaultLocalization('es').EmailSubject__c, defaultEs.subject);
			//French
			Recipient.EmailSettings defaultFr = Localization.getDefaultEmailSettings('fr');
			System.assertEquals(defaultLocalization('fr').EmailSubject__c, defaultFr.subject);
			//Italian
			Recipient.EmailSettings defaultIt = Localization.getDefaultEmailSettings('it');
			System.assertEquals(defaultLocalization('it').EmailSubject__c, defaultIt.subject);
			//Japanese
			Recipient.EmailSettings defaultJa = Localization.getDefaultEmailSettings('ja');
			System.assertEquals(defaultLocalization('ja').EmailSubject__c, defaultJa.subject);
			//Korean
			Recipient.EmailSettings defaultKo = Localization.getDefaultEmailSettings('ko');
			System.assertEquals(defaultLocalization('ko').EmailSubject__c, defaultKo.subject);
			//Dutch
			Recipient.EmailSettings defaultNl = Localization.getDefaultEmailSettings('nl');
			System.assertEquals(defaultLocalization('nl').EmailSubject__c, defaultNl.subject);
			//Portuguese Brazilian
			Recipient.EmailSettings defaultPtbr = Localization.getDefaultEmailSettings('pt_BR');
			System.assertEquals(defaultLocalization('pt_BR').EmailSubject__c, defaultPtbr.subject);
			//Russian
			Recipient.EmailSettings defaultRu = Localization.getDefaultEmailSettings('ru');
			System.assertEquals(defaultLocalization('ru').EmailSubject__c, defaultRu.subject);
			//Chinese
			Recipient.EmailSettings defaultZhcn = Localization.getDefaultEmailSettings('zh_CN');
			System.assertEquals(defaultLocalization('zh_CN').EmailSubject__c, defaultZhcn.subject);

			Boolean getDefaultSettingsLanguageCodeError = false;
			try {
				Localization.getDefaultEmailSettings('aa');
			} catch (DocuSignException excp) {
				getDefaultSettingsLanguageCodeError = true;
			}
			System.assert(getDefaultSettingsLanguageCodeError);
			Test.stopTest();
		}
	}

	static User getUser(final String localeKey) {
		String email = UUID.randomUUID().toShortString() + '@unit.test';
		return new User(
			FirstName = 'Unit',
			LastName = 'Test',
			Username = email,
			Email = email,
			Alias = 'test',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = localeKey,
			EmailEncodingKey = 'ISO-8859-1',
			ProfileId = UserInfo.getProfileId(),
			LanguageLocaleKey = localeKey);
	}

	static testMethod void test_updateEmailSettings() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			// Add language
			final Boolean r1 = Localization.updateEmailSettings(new Recipient.EmailSettings('ru', 'Russian', 'test subject ru', ''));
			final Boolean r2 = Localization.updateEmailSettings(new Recipient.EmailSettings('en', 'English', 'test subject en', ''));
			// Remove language (subject blank)
			final Boolean r3 = Localization.updateEmailSettings(new Recipient.EmailSettings('ru', 'Russian', null, null));
			final Boolean r4 = Localization.updateEmailSettings(new Recipient.EmailSettings(Localization.DEFAULT_LANGUAGE, 'Default', null, null));
			Test.stopTest();

			System.assert(r1);
			System.assert(r2);
			System.assert(r3);
			System.assert(!r4);
		}
	}

	static testMethod void test_getCurrentLanguage() {
		TestUtils.createAccountConfiguration();
		User u1 = getUser('es_MX');
		User u2 = getUser('FR');
		User u3 = getUser('da');
		insert new List<User> { u1, u2, u3 };

		Test.startTest();
		System.runAs(u1) {
			System.assertEquals('es', Localization.getCurrentLanguage());
		}

		System.runAs(u2) {
			System.assertEquals('fr', Localization.getCurrentLanguage());
		}

		System.runAs(u3) {
			System.assertEquals('da', Localization.getCurrentLanguage());
		}
		Test.stopTest();
	}

	static testMethod void test_isEmailLocalizationEnabled_disabled() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			final Boolean result = Localization.isEmailLocalizationEnabled();
			Test.stopTest();

			System.assert(!result);
		}
	}

	static testMethod void test_isEmailLocalizationEnabled_enabled() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Localization.updateEmailSettings(new Recipient.EmailSettings('ru', 'Russian', 'test subject ru', ''));

			Test.startTest();
			final Boolean result = Localization.isEmailLocalizationEnabled();
			Test.stopTest();

			System.assert(result);
		}
	}

	static testMethod void test_getEmailSettingsForCurrentLanguage() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			Localization.updateEmailSettings(new Recipient.EmailSettings('it', 'Italian', 'subject-italian', 'message-italian'));
		}

		User u1 = getUser('en_US');
		User u2 = getUser('IT');
		User u3 = getUser('fi');
		insert new List<User> { u1, u2, u3 };
		Recipient.EmailSettings es1, es2;

		Test.startTest();
		System.runAs(u1) {
			Recipient.EmailSettings result = Localization.getEmailSettingsForCurrentLanguage();
			System.assertNotEquals(null, result);
			System.assertEquals('en', result.language);
		}
		System.runAs(u2) {
			Recipient.EmailSettings result = Localization.getEmailSettingsForCurrentLanguage();
			System.assertNotEquals(null, result);
			System.assertEquals('it', result.language);
			System.assertEquals('subject-italian', result.subject);
			System.assertEquals('message-italian', result.message);
		}
		System.runAs(u3) {
			Recipient.EmailSettings result = Localization.getEmailSettingsForCurrentLanguage();
			System.assertNotEquals(null, result);
			System.assertEquals(Localization.DEFAULT_LANGUAGE, result.language);
		}
		Test.stopTest();
	}

	static testMethod void test_getDefaultChatterText() {
		System.assertNotEquals(null, Localization.getDefaultChatterText(Localization.EN));
		System.assertNotEquals(null, Localization.getDefaultChatterText(Localization.DE));
		System.assertNotEquals(null, Localization.getDefaultChatterText(Localization.ES));
		System.assertNotEquals(null, Localization.getDefaultChatterText(Localization.FR));
		System.assertNotEquals(null, Localization.getDefaultChatterText(Localization.IT));
		System.assertNotEquals(null, Localization.getDefaultChatterText(Localization.JA));
		System.assertNotEquals(null, Localization.getDefaultChatterText(Localization.KO));
		System.assertNotEquals(null, Localization.getDefaultChatterText(Localization.NL));
		System.assertNotEquals(null, Localization.getDefaultChatterText(Localization.PT_BR));
		System.assertNotEquals(null, Localization.getDefaultChatterText(Localization.RU));
		System.assertNotEquals(null, Localization.getDefaultChatterText(Localization.ZH_CN));
	}

	static testMethod void test_getChatterText() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			System.assertNotEquals(null, Localization.getChatterText());
			Test.stopTest();
		}
	}

	static testMethod void test_updateChatterText() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			final Localization.ChatterText text = new Localization.ChatterText(
				'a',
				'b',
				'c',
				'd',
				'e',
				'f',
				'g',
				'h',
				'i',
				'j');

			Test.startTest();
			try {
				Localization.updateChatterText(null);
				throw new AssertException('Expected updateChatterText to fail with null input');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedChatterText, ex.getMessage());
			}
			Localization.updateChatterText(text);
			Test.stopTest();

			ChatterSettings__c c = ChatterSettings__c.getOrgDefaults();
			System.assertEquals('a', c.EnvelopeSent__c);
			System.assertEquals('b', c.EnvelopeDelivered__c);
			System.assertEquals('c', c.EnvelopeCompleted__c);
			System.assertEquals('d', c.EnvelopeDeclined__c);
			System.assertEquals('e', c.EnvelopeVoided__c);
			System.assertEquals('f', c.RecipientSent__c);
			System.assertEquals('g', c.RecipientDelivered__c);
			System.assertEquals('h', c.RecipientCompleted__c);
			System.assertEquals('i', c.RecipientSigned__c);
			System.assertEquals('j', c.RecipientDeclined__c);
		}
	}

	static testMethod void test_getChatterSettings() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			final List<Localization.ChatterSettings> cs = Localization.getChatterSettings();
			Test.stopTest();

			System.assertNotEquals(null, cs);
			System.assertEquals(12, cs.size());
			System.assertEquals(Localization.CURRENT, cs[0].language);
		}
	}

	static testMethod void test_ChatterText_getEnvelopeStatusText() {
		Localization.ChatterText ct = new Localization.ChatterText(
			'Envelope Sent',
			'Envelope Delivered',
			'Envelope Completed',
			'Envelope Declined',
			'Envelope Voided',
			'Recipient Sent',
			'Recipient Delivered',
			'Recipient Completed',
			'Recipient Signed',
			'Recipient Declined');

		Test.startTest();
		System.assertEquals(null, ct.getEnvelopeStatusText(null));
		System.assertEquals(null, ct.getEnvelopeStatusText(''));
		System.assertEquals(null, ct.getEnvelopeStatusText('\t'));
		System.assertEquals(null, ct.getEnvelopeStatusText('bad'));
		System.assertEquals(ct.envelopeCompleted, ct.getEnvelopeStatusText(Status.COMPLETED));
		System.assertEquals(ct.envelopeDeclined, ct.getEnvelopeStatusText(Status.DECLINED));
		System.assertEquals(ct.envelopeDelivered, ct.getEnvelopeStatusText(Status.DELIVERED));
		System.assertEquals(ct.envelopeSent, ct.getEnvelopeStatusText(Status.SENT));
		System.assertEquals(ct.envelopeVoided, ct.getEnvelopeStatusText(Status.VOIDED));
		Test.stopTest();
	}

	static testMethod void test_ChatterText_getRecipientStatusText() {
		Localization.ChatterText ct = new Localization.ChatterText(
			'Envelope Sent',
			'Envelope Delivered',
			'Envelope Completed',
			'Envelope Declined',
			'Envelope Voided',
			'Recipient Sent',
			'Recipient Delivered',
			'Recipient Completed',
			'Recipient Signed',
			'Recipient Declined');

		Test.startTest();
		System.assertEquals(null, ct.getRecipientStatusText(null));
		System.assertEquals(null, ct.getRecipientStatusText(''));
		System.assertEquals(null, ct.getRecipientStatusText('\t'));
		System.assertEquals(null, ct.getRecipientStatusText('bad'));
		System.assertEquals(ct.recipientCompleted, ct.getRecipientStatusText(Status.COMPLETED));
		System.assertEquals(ct.recipientDeclined, ct.getRecipientStatusText(Status.DECLINED));
		System.assertEquals(ct.recipientDelivered, ct.getRecipientStatusText(Status.DELIVERED));
		System.assertEquals(ct.recipientSent, ct.getRecipientStatusText(Status.SENT));
		System.assertEquals(ct.recipientSigned, ct.getRecipientStatusText(Status.SIGNED));
		Test.stopTest();
	}
}
