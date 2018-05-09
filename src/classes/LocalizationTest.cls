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

	@IsTest
	static void test_email_settings() {
		List<Recipient.EmailSettings> localizationSettings;
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			localizationSettings = Localization.getEmailSettings();
			// By default localization settings should only contain english as a language setting
			System.assertEquals(1, localizationSettings.size());

			Localization.save(new List<Recipient.EmailSettings> {
				new Recipient.EmailSettings('en', 'English', 'test subject en', 'm'),
				new Recipient.EmailSettings('de', 'German', 'test subject de', 'm'),
				new Recipient.EmailSettings('es', 'Spanish', 'test subject es', 'm'),
				new Recipient.EmailSettings('fr', 'French', 'test subject fr', 'm'),
				new Recipient.EmailSettings('it', 'Italian', 'test subject it', 'm'),
				new Recipient.EmailSettings('ja', 'Japanese', 'test subject ja', 'm'),
				new Recipient.EmailSettings('ko', 'Korean', 'test subject ko', 'm'),
				new Recipient.EmailSettings('nl', 'Dutch', 'test subject nl', 'm'),
				new Recipient.EmailSettings('pt_BR', 'Portuguese-Brazil', 'test subject pt_BR', 'm'),
				new Recipient.EmailSettings('ru', 'Russian', 'test subject ru', 'm'),
				new Recipient.EmailSettings('zh_CN', 'Chinese-simplified', 'test subject zh_CN', 'm')
			});

			Recipient.EmailSettings enSetting = Localization.getEmailSettings('en');
			System.assertEquals('test subject en', enSetting.subject);

			Recipient.EmailSettings deSetting = Localization.getEmailSettings('de');
			System.assertEquals('test subject de', deSetting.subject);

			Recipient.EmailSettings esSetting = Localization.getEmailSettings('es');
			System.assertEquals('test subject es', esSetting.subject);

			Recipient.EmailSettings frSetting = Localization.getEmailSettings('fr');
			System.assertEquals('test subject fr', frSetting.subject);

			Recipient.EmailSettings itSetting = Localization.getEmailSettings('it');
			System.assertEquals('test subject it', itSetting.subject);

			Recipient.EmailSettings jaSetting = Localization.getEmailSettings('ja');
			System.assertEquals('test subject ja', jaSetting.subject);

			Recipient.EmailSettings koSetting = Localization.getEmailSettings('ko');
			System.assertEquals('test subject ko', koSetting.subject);

			Recipient.EmailSettings nlSetting = Localization.getEmailSettings('nl');
			System.assertEquals('test subject nl', nlSetting.subject);

			Recipient.EmailSettings ptbrSetting = Localization.getEmailSettings('pt_BR');
			System.assertEquals('test subject pt_BR', ptbrSetting.subject);

			Recipient.EmailSettings ruSetting = Localization.getEmailSettings('ru');
			System.assertEquals('test subject ru', ruSetting.subject);

			Recipient.EmailSettings zhCNSetting = Localization.getEmailSettings('zh_CN');
			System.assertEquals('test subject zh_CN', zhCNSetting.subject);

			localizationSettings = Localization.getEmailSettings();
			//verifying all languages have been added to the email settings
			System.assertEquals(11, localizationSettings.size());

			System.assertEquals(null, Localization.getEmailSettings('aa'));

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
			// All
			List<Recipient.EmailSettings> defaults = Localization.getDefaultEmailSettings();
			System.assertEquals(11, defaults.size());

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

	@IsTest
	static void test_save_Recipient_EmailSettings_success() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			insert new List<EnvelopeLocalization__c> {
				new EnvelopeLocalization__c(
					Name = Localization.getLabel('de'),
					Language__c = 'de',
					EmailSubject__c = 'de subject',
					EmailMessage__c = 'de message'),
				new EnvelopeLocalization__c(
					Name = Localization.getLabel('ru'),
					Language__c = 'ru',
					EmailSubject__c = 'ru subject',
					EmailMessage__c = 'ru message')
			};

			Test.startTest();
			List<Recipient.EmailSettings> result = Localization.save(new List<Recipient.EmailSettings> {
				// new IT
				new Recipient.EmailSettings('it', 'replaced', 'it subject', 'it message'),
				// updated DE
				new Recipient.EmailSettings('de', 'replaced', 'de subject2', 'de message2')
				// delete RU
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(3, result.size()); // IT, DE, DEFAULT

			Boolean foundDefault = false, foundDE = false, foundIT = false;
			for (Recipient.EmailSettings s : result) {
				System.assertNotEquals(null, s);
				if (s.language == Localization.DEFAULT_LANGUAGE) {
					foundDefault = true;
				} else if (s.language == Localization.DE) {
					foundDE = true;
					System.assertEquals(Localization.getLabel(Localization.DE), s.languageLabel);
					System.assertEquals('de subject2', s.subject);
					System.assertEquals('de message2', s.message);
				} else if (s.language == Localization.IT) {
					foundIT = true;
					System.assertEquals(Localization.getLabel(Localization.IT), s.languageLabel);
					System.assertEquals('it subject', s.subject);
					System.assertEquals('it message', s.message);
				} else {
					throw new AssertException('Unexpected localization: ' + s);
				}
			}
			System.assert(foundDefault);
			System.assert(foundIT);
			System.assert(foundDE);
		}
	}

	@IsTest
	static void test_save_Recipient_EmailSettings_unauthorized() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			try {
				Localization.save(new List<Recipient.EmailSettings> { new Recipient.EmailSettings('ab', '', '', '') });
				throw new AssertException('Expected save to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.CannotCreateObject + ' ' + Application.namespacePrefix + 'EnvelopeLocalization__c', ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_save_Recipient_EmailSettings_error() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				Localization.save((List<Recipient.EmailSettings>)null);
				throw new AssertException('Expected save to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				Localization.save(new List<Recipient.EmailSettings> { new Recipient.EmailSettings(Localization.PT_BR, 'blah', '', '') });
				throw new AssertException('Expected save to fail');
			} catch (ValidationException ex) {
				System.assertEquals(Label.InvalidEmailSettings + '\n' + Label.AllValuesMustNotBeBlank, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getCurrentLanguage() {
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

	@IsTest
	static void test_isEmailLocalizationEnabled_disabled() {
		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			final Boolean result = Localization.isEmailLocalizationEnabled();
			Test.stopTest();

			System.assert(!result);
		}
	}

	@IsTest
	static void test_isEmailLocalizationEnabled_enabled() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			Localization.save(new List<Recipient.EmailSettings> { new Recipient.EmailSettings('ru', 'Russian', 'test subject ru', 'm') });
		}

		System.runAs(TestUtils.createDocuSignUser()) {
			Test.startTest();
			System.assert(Localization.isEmailLocalizationEnabled());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEmailSettingsForCurrentLanguage() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
			Localization.save(new List<Recipient.EmailSettings> { new Recipient.EmailSettings('it', 'Italian', 'subject-italian', 'message-italian') });
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

	@IsTest
	static void test_getDefaultChatterText() {
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

	@IsTest
	static void test_getChatterText() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			System.assertNotEquals(null, Localization.getChatterText());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_save_ChatterText() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Localization.ChatterText text = new Localization.ChatterText(
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
			Localization.ChatterText text1 = new Localization.ChatterText(
				'a',
				null,
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
				Localization.save((Localization.ChatterText)null);
				throw new AssertException('Expected save to fail with null input');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedChatterText, ex.getMessage());
			}
			try {
				Localization.save(text1);
				throw new AssertException('Expected save to fail with invalid input');
			} catch (ValidationException ex) {
				System.assert(ex.getMessage().startsWith(Label.InvalidChatterText));
			}
			Localization.save(text);
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

	@IsTest
	static void test_getChatterSettings() {
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

	@IsTest
	static void test_ChatterText_getEnvelopeStatusText() {
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
		System.assertEquals(ct.envelopeCompleted, ct.getEnvelopeStatusText(Envelope.STATUS_COMPLETED));
		System.assertEquals(ct.envelopeDeclined, ct.getEnvelopeStatusText(Envelope.STATUS_DECLINED));
		System.assertEquals(ct.envelopeDelivered, ct.getEnvelopeStatusText(Envelope.STATUS_DELIVERED));
		System.assertEquals(ct.envelopeSent, ct.getEnvelopeStatusText(Envelope.STATUS_SENT));
		System.assertEquals(ct.envelopeVoided, ct.getEnvelopeStatusText(Envelope.STATUS_VOIDED));
		Test.stopTest();
	}

	@IsTest
	static void test_ChatterText_getRecipientStatusText() {
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
		System.assertEquals(ct.recipientCompleted, ct.getRecipientStatusText(Recipient.STATUS_COMPLETED));
		System.assertEquals(ct.recipientDeclined, ct.getRecipientStatusText(Recipient.STATUS_DECLINED));
		System.assertEquals(ct.recipientDelivered, ct.getRecipientStatusText(Recipient.STATUS_DELIVERED));
		System.assertEquals(ct.recipientSent, ct.getRecipientStatusText(Recipient.STATUS_SENT));
		System.assertEquals(ct.recipientSigned, ct.getRecipientStatusText(Recipient.STATUS_SIGNED));
		Test.stopTest();
	}

	@IsTest
	static void test_validate_Recipient_EmailSettings() {
		Recipient.EmailSettings es1 = new Recipient.EmailSettings(Localization.ES, '', 's', 'm');
		Recipient.EmailSettings es2 = new Recipient.EmailSettings(null, '', 's', 'm');
		Recipient.EmailSettings es3 = new Recipient.EmailSettings('l', '', '  \n', 'm');
		Recipient.EmailSettings es4 = new Recipient.EmailSettings('l', '', 's', '');
		Recipient.EmailSettings es5 = null;
		Recipient.EmailSettings es6 = new Recipient.EmailSettings('l', '', 's', '');

		Test.startTest();
		System.assert(Localization.validate(es1).isValid);
		System.assert(!Localization.validate(es2).isValid);
		System.assert(!Localization.validate(es3).isValid);
		System.assert(!Localization.validate(es4).isValid);
		System.assert(!Localization.validate(es5).isValid);
		Test.stopTest();
	}

	@IsTest
	static void test_validate_ChatterText() {
		Localization.ChatterText ct1 = new Localization.ChatterText(
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
		Localization.ChatterText ct2 = new Localization.ChatterText(
			'Envelope Sent',
			'Envelope Delivered',
			'Envelope Completed',
			' ',
			'Envelope Voided',
			'Recipient Sent',
			'Recipient Delivered',
			'Recipient Completed',
			'Recipient Signed',
			'Recipient Declined');
		Localization.ChatterText ct3 = new Localization.ChatterText(
			'Envelope Sent',
			'Envelope Delivered',
			'Envelope Completed',
			'Envelope Declined',
			null,
			'Recipient Sent',
			'Recipient Delivered',
			'Recipient Completed',
			'Recipient Signed',
			'Recipient Declined');
		Localization.ChatterText ct4 = null;

		Test.startTest();
		System.assert(Localization.validate(ct1).isValid);
		System.assert(!Localization.validate(ct2).isValid);
		System.assert(!Localization.validate(ct3).isValid);
		System.assert(!Localization.validate(ct4).isValid);
		Test.stopTest();
	}
}
