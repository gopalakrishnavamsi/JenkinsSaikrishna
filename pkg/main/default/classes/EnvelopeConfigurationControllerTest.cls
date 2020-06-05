@IsTest
private class EnvelopeConfigurationControllerTest {

	@IsTest
	static void test_constructor_default() {
		PageReference pg = Page.EnvelopeConfigurationNavigator;
		Test.setCurrentPage(pg);
		Test.startTest();
		EnvelopeConfigurationController result = new EnvelopeConfigurationController();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals('/' + EnvelopeConfiguration__c.getSObjectType().getDescribe().getKeyPrefix() + '/o', result.objectHomeUrl);
	}

	@IsTest
	static void test_constructor_standard() {
		EnvelopeConfiguration__c envConfig = TestUtils.createEnvelopeConfiguration();

		Test.startTest();
		new EnvelopeConfigurationController(null);
		EnvelopeConfigurationController result = new EnvelopeConfigurationController(new ApexPages.StandardController(envConfig));
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals('/' + EnvelopeConfiguration__c.getSObjectType().getDescribe().getKeyPrefix() + '/o', result.objectHomeUrl);
	}

	@IsTest
	static void test_createEnvelopeConfiguration_success() {
		ESignatureAPIMock.success();
		EnvelopeConfiguration config = new EnvelopeConfiguration(
			null,
			'Test Envelope Configuration',
			'Account',
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null);
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			EnvelopeConfiguration envConfig = EnvelopeConfigurationController.createEnvelopeConfiguration(Json.serialize(config));
			Test.stopTest();
			System.assertNotEquals(envConfig.id, null);
			System.assertNotEquals(envConfig.docuSignId, null);
			System.assertEquals(envConfig.name, 'Test Envelope Configuration');
			System.assertEquals(envConfig.sourceObject, 'Account');
		}
	}

	@IsTest
	static void test_createEnvelopeConfiguration_unauthorized() {
		ESignatureAPIMock.success();
		EnvelopeConfiguration config = new EnvelopeConfiguration(
			null,
			'Test Envelope Configuration',
			'Account',
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null);
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeConfiguration envConfig = EnvelopeConfigurationController.createEnvelopeConfiguration(Json.serialize(config));
				throw new AssertException('Expected failure');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_redirectToEnvelopeConfigUrl_success() {
		EnvelopeConfiguration__c envConfig = TestUtils.createEnvelopeConfiguration();
		PageReference pg = Page.EnvelopeConfigurationNavigator;
		Test.setCurrentPage(pg);
		Test.startTest();
		EnvelopeConfigurationController controller = new EnvelopeConfigurationController(new ApexPages.StandardController(envConfig));
		controller.envelopeConfigId = envConfig.Id;
		PageReference redirectpg = controller.redirectToNewConfigUrl();
		System.assertEquals(redirectpg.getParameters().get('id'), envConfig.Id);
		Test.stopTest();
	}

	@IsTest
	static void test_updateEnvelopeConfiguration_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			EnvelopeConfiguration__c envConfig = TestUtils.createEnvelopeConfiguration();
			System.assertNotEquals(envConfig.Id, null);
			final String UPDATED_ENV_CONFIG_NAME = envConfig.Name + 'Updated';
			EnvelopeConfiguration config = new EnvelopeConfiguration(
				envConfig.Id,
				UPDATED_ENV_CONFIG_NAME,
				envConfig.SourceObject__c,
				UUID.parse(envConfig.DocuSignId__c),
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null);
			Test.startTest();
			EnvelopeConfiguration updatedEnvelopeConfiguration =
				EnvelopeConfigurationController.updateEnvelopeConfiguration(Json.serialize(config), false, null);
			Test.stopTest();
			System.assertEquals(updatedEnvelopeConfiguration.name, UPDATED_ENV_CONFIG_NAME);
		}
	}

	@IsTest
	static void test_parseUpdates() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			ContentVersion cv = TestUtils.createContentVersion();
			EnvelopeConfiguration__c dbec = TestUtils.createEnvelopeConfiguration(
				null,
				'Opportunity');
			EnvelopeConfiguration ec = new EnvelopeConfiguration(
				dbec.Id,
				UUID.randomUUID().toString(),
				dbec.SourceObject__c,
				null,
				new List<Document> {
					new EnvelopeConfiguration.TemplateDocument(
						null,
						cv.ContentDocumentId,
						1,
						cv.Title,
						cv.FileExtension,
						false,
						true),
					new EnvelopeConfiguration.SourceFiles(
						null,
						null,
						2,
						true,
						false)
				},
				new List<Recipient> {
					new EnvelopeConfiguration.LookupRecipient(
						new Query.Relationship(
							true,
							'Owner',
							'Owner',
							'User'),
						Recipient.TYPE_EMBEDDED_SIGNER,
						1,
						'r1',
						true,
						false),
					new EnvelopeConfiguration.RelatedRecipients(
						new Query.Relationship(
							false,
							'OpportunityContactRoles',
							'Opportunity Contact Roles',
							'OpportunityContactRole'),
						null,
						Recipient.TYPE_CARBON_COPY,
						2,
						true,
						new List<String> { 'r1', 'r2', 'r3' },
						false,
						true)
				},
				new List<CustomField> {
					CustomField.newTextField('tf', 'tv', false, true),
					CustomField.newListField('lf', 'lv2', new List<String> { 'lv1', 'lv2', 'lv3' }, true, false)
				},
				new Notifications(true, 2, 1, true, 9, 7, false),
				's',
				'm',
				new List<Tab> {
					Tab.newMergeField(Tab.TYPE_TEXT, 'Opportunity.Name', false, false),
					Tab.newMergeField(Tab.TYPE_NUMBER, 'Opportunity.Amount', true, true)
				},
				Envelope.DEFAULT_PERMISSIONS,
				Envelope.DEFAULT_OPTIONS,
				false);

			String ecJSON = JSON.serialize(ec);
			Test.startTest();
			EnvelopeConfiguration result = EnvelopeConfigurationController.parseUpdates(ecJSON, true);
			Test.stopTest();
			System.assertNotEquals(result, null);
			System.assertEquals(result.recipients.size(), 2);
			System.assertEquals(result.recipients[0] instanceof EnvelopeConfiguration.LookupRecipient, true);
			System.assertEquals(result.recipients[1] instanceof EnvelopeConfiguration.RelatedRecipients, true);
			System.assertEquals(result.documents.size(), 2);
			System.assertEquals(result.documents[0] instanceof EnvelopeConfiguration.TemplateDocument, true);
			System.assertEquals(result.documents[1] instanceof EnvelopeConfiguration.SourceFiles, true);
		}
	}

	@IsTest
	static void test_parseRecipients() {
		EnvelopeConfiguration.LookupRecipient r1 = (EnvelopeConfiguration.LookupRecipient)new EnvelopeConfiguration.LookupRecipient(
			new Query.Relationship(
				true,
				'rn1',
				'rl1',
				'rt1'),
			Recipient.TYPE_AGENT,
			1,
			'r1',
			false,
			true)
			.withAuthentication(new Recipient.Authentication(
				'1111',
				true,
				new List<String> { '1111111' }))
			.withEmailSettings(new Recipient.EmailSettings(
				'l1',
				'll1',
				's1',
				'm1'));
		EnvelopeConfiguration.RelatedRecipients r2 = (EnvelopeConfiguration.RelatedRecipients)new EnvelopeConfiguration.RelatedRecipients(
			new Query.Relationship(
				false,
				'rn2',
				'rl2',
				'rt2'),
			new Query.Filter(
				'filterBy1',
				'orderBy1',
				11),
			Recipient.TYPE_WITNESS,
			2,
			true,
			new List<String> { 'r1', 'r2', 'r3' },
			true,
			false)
			.withAuthentication(new Recipient.Authentication(
				'1111',
				true,
				new List<String> { '1111111' }))
			.withEmailSettings(new Recipient.EmailSettings(
				'l1',
				'll1',
				's1',
				'm1'));
		Recipient r3 = new Recipient(
			null,
			Recipient.TYPE_SIGNER,
			3,
			3,
			new Recipient.Role('Signer 1'),
			UUID.randomUUID().toString(),
			UUID.randomUUID() + '@unit.test',
			new SigningGroup(1111, 'sg1'),
			'1111',
			new Recipient.Authentication(
				'1111',
				true,
				new List<String> { '1111' }),
			'n1',
			new Recipient.EmailSettings(
				'l1',
				null,
				's1',
				's2'),
			null,
			null,
			true,
			null,
			true,
			true);
		List<Object> recipients = (List<Object>)JSON.deserializeUntyped(JSON.serialize(new List<Recipient> { r1, r2, r3 }));
		List<Object> emptyRecipients = new List<Object>();

		Test.startTest();
		List<Recipient> result1 = EnvelopeConfigurationController.parseRecipients(recipients);
		List<Recipient> result2 = EnvelopeConfigurationController.parseRecipients(emptyRecipients);
		Test.stopTest();
		System.assertEquals(result1.size(), 3);
		System.assertEquals(result1[0] instanceof EnvelopeConfiguration.LookupRecipient, true);
		System.assertEquals(result1[1] instanceof EnvelopeConfiguration.RelatedRecipients, true);
		System.assertEquals(Collection.isEmpty(result2), true);
	}

	@IsTest
	static void test_parseDocuments() {
		ContentVersion cv = TestUtils.createContentVersion();
		EnvelopeConfiguration.TemplateDocument d1 = new EnvelopeConfiguration.TemplateDocument(
			null,
			cv.ContentDocumentId,
			1,
			cv.Title,
			cv.FileExtension,
			true,
			false);
		EnvelopeConfiguration.SourceFiles d2 = new EnvelopeConfiguration.SourceFiles(
			null,
			new Query.Filter(
				'FILTER_BY',
				'ORDER_BY',
				10),
			2,
			false,
			true);
		List<Object> ds = (List<Object>)JSON.deserializeUntyped(JSON.serialize(new List<Document> { d1, d2 }));
		List<Object> emptyDocs = new List<Object>();

		Test.startTest();
		List<Document> result1 = EnvelopeConfigurationController.parseDocuments(ds, true);
		List<Document> result2 = EnvelopeConfigurationController.parseDocuments(emptyDocs, false);
		Test.stopTest();

		System.assertEquals(result1.size(), 2);
		System.assertEquals(result1[0] instanceof EnvelopeConfiguration.TemplateDocument, true);
		System.assertEquals(result1[1] instanceof EnvelopeConfiguration.SourceFiles, true);
		System.assert(Collection.isEmpty(result2));
	}

	@IsTest
	static void test_updateEnvelopeConfiguration_unauthorized() {
		ESignatureAPIMock.success();
		EnvelopeConfiguration__c envConfig = TestUtils.createEnvelopeConfiguration();
		System.assertNotEquals(envConfig.Id, null);
		final String UPDATED_ENV_CONFIG_NAME = envConfig.Name + 'Updated';
		System.runAs(UserMock.createDocuSignUser(false)) {
			EnvelopeConfiguration config = new EnvelopeConfiguration(
				envConfig.Id,
				'Test Envelope Config',
				'Account',
				UUID.parse(envConfig.DocuSignId__c),
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null);
			Test.startTest();
			try {
				EnvelopeConfigurationController.updateEnvelopeConfiguration(Json.serialize(config), false, null);
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEnvelopeConfiguration_success() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			EnvelopeConfiguration__c envConfig = TestUtils.createEnvelopeConfiguration();
			System.assertNotEquals(envConfig.Id, null);
			Test.startTest();
			EnvelopeConfiguration envelopeConfiguration =
				EnvelopeConfigurationController.getEnvelopeConfiguration(envConfig.Id);
			Test.stopTest();
			System.assertNotEquals(envelopeConfiguration.name, null);
			System.assertNotEquals(envelopeConfiguration.docuSignId, null);
		}
	}

	@IsTest
	static void test_getEnvelopeConfiguration_failure() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			try {
				EnvelopeConfiguration envelopeConfiguration =
					EnvelopeConfigurationController.getEnvelopeConfiguration(null);
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.UndefinedId, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteEnvelopeConfiguration_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationController.deleteEnvelopeConfiguration(null);
				throw new AssertException('Expected failure');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteEnvelopeConfiguration_invalid() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationController.deleteEnvelopeConfiguration(null);
				throw new AssertException('Expected failure');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.UndefinedId, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteEnvelopeConfiguration_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			EnvelopeConfiguration__c ec = TestUtils.createEnvelopeConfiguration();

			Test.startTest();
			System.assert(EnvelopeConfigurationController.deleteEnvelopeConfiguration(ec.Id));
			Test.stopTest();

			System.assertEquals(0, Collection.size([SELECT Id FROM EnvelopeConfiguration__c WHERE Id = :ec.Id]));
		}
	}

	@IsTest
	static void test_getLookupFields_success() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			SObjectType opportunityType = Opportunity.getSObjectType();
			Test.startTest();
			List<Query.Relationship> results = EnvelopeConfigurationController.getLookupFields(String.valueOf(opportunityType));
			Test.stopTest();
			System.assert(Collection.isNotEmpty(results));
			System.assert(String.isNotEmpty(results[0].name));
			System.assert(String.isNotEmpty(results[0].label));
			System.assert(String.isNotEmpty(results[0].relatesTo));
			System.assertEquals(results[0].isLookup, true);
		}
	}

	@IsTest
	static void test_childRelationships_success() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			SObjectType opportunityType = Opportunity.getSObjectType();
			Test.startTest();
			List<Query.Relationship> results = EnvelopeConfigurationController.getChildRelationships(String.valueOf(opportunityType));
			Test.stopTest();
			System.assert(Collection.isNotEmpty(results));
			System.assert(String.isNotEmpty(results[0].name));
			System.assert(String.isNotEmpty(results[0].label));
			System.assert(String.isNotEmpty(results[0].relatesTo));
			System.assertEquals(results[0].isLookup, false);
		}
	}

	@IsTest
	static void test_getLookupFields_unauthorized() {
		System.runAs(UserMock.createDocuSignUser()) {
			SObjectType opportunityType = Opportunity.getSObjectType();
			Test.startTest();
			try {
				List<Query.Relationship> results = EnvelopeConfigurationController.getLookupFields(String.valueOf(opportunityType));
				throw new AssertException('Expected failure');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getChildRelationships_unauthorized() {
		System.runAs(UserMock.createDocuSignUser()) {
			SObjectType opportunityType = Opportunity.getSObjectType();
			Test.startTest();
			try {
				List<Query.Relationship> results = EnvelopeConfigurationController.getChildRelationships(String.valueOf(opportunityType));
				throw new AssertException('Expected failure');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteContentDocument_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Boolean testResult;
			ContentVersion testContentVersion1 = TestUtils.createContentVersion();
			ContentVersion testContentVersion2 = TestUtils.createContentVersion();
			EnvelopeConfiguration__c envConfig = TestUtils.createEnvelopeConfiguration();
			System.assertNotEquals(envConfig.Id, null);
			System.assertNotEquals(testContentVersion1.ContentDocumentId, null);
			System.assertNotEquals(testContentVersion2.ContentDocumentId, null);
			List<Id> contentVersionIds = new List<Id> { testContentVersion1.Id, testContentVersion2.Id };
			List<Id> contentDocumentIds = new List<Id> { testContentVersion1.ContentDocumentId, testContentVersion2.ContentDocumentId };

			EnvelopeConfiguration config = new EnvelopeConfiguration(
				envConfig.Id,
				envConfig.Name,
				envConfig.SourceObject__c,
				UUID.parse(envConfig.DocuSignId__c),
				new List<Document> {
					new EnvelopeConfiguration.TemplateDocument(
						null,
						testContentVersion1.ContentDocumentId,
						1,
						testContentVersion1.Title,
						testContentVersion1.FileExtension,
						false,
						true),
					new EnvelopeConfiguration.TemplateDocument(
						null,
						testContentVersion2.ContentDocumentId,
						1,
						testContentVersion2.Title,
						testContentVersion2.FileExtension,
						false,
						true)
				},
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null);
			EnvelopeConfigurationDocument__c templateDocument1 = TestUtils.createEnvelopeConfigurationDocument(
				testContentVersion1.Title,
				envConfig.Id,
				testContentVersion1.ContentDocumentId,
				EnvelopeConfiguration.DOCUMENT_TYPE_TEMPLATE_DOCUMENT
			);
			System.assertNotEquals(templateDocument1.Id, null);
			EnvelopeConfigurationDocument__c templateDocument2 = TestUtils.createEnvelopeConfigurationDocument(
				testContentVersion2.Title,
				envConfig.Id,
				testContentVersion2.ContentDocumentId,
				EnvelopeConfiguration.DOCUMENT_TYPE_TEMPLATE_DOCUMENT
			);
			System.assertNotEquals(templateDocument2.Id, null);
			Test.startTest();
			config = new EnvelopeConfiguration(
				envConfig.Id,
				envConfig.Name,
				envConfig.SourceObject__c,
				UUID.parse(envConfig.DocuSignId__c),
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null);
			EnvelopeConfiguration updatedEnvelopeConfiguration = EnvelopeConfigurationController.updateEnvelopeConfiguration(
				Json.serialize(config),
				false,
				contentDocumentIds);
			Test.stopTest();
			System.assertEquals(updatedEnvelopeConfiguration.documents.size(), 0);
			System.assertEquals([SELECT Id FROM ContentVersion WHERE Id IN:contentVersionIds].size(), 0);
			System.assertEquals([SELECT Id FROM ContentDocument WHERE Id IN:contentDocumentIds].size(), 0);
		}
	}

	@IsTest
	static void test_deleteContentDocument_unauthorized() {
		ESignatureAPIMock.success();
		EnvelopeConfiguration__c envConfig;
		EnvelopeConfiguration config;
		List<Id> contentDocumentIds;
		List<Id> contentVersionIds;

		Boolean testResult;
		ContentVersion testContentVersion1 = TestUtils.createContentVersion();
		ContentVersion testContentVersion2 = TestUtils.createContentVersion();
		envConfig = TestUtils.createEnvelopeConfiguration();
		System.assertNotEquals(envConfig.Id, null);
		System.assertNotEquals(testContentVersion1.ContentDocumentId, null);
		System.assertNotEquals(testContentVersion2.ContentDocumentId, null);
		contentVersionIds = new List<Id> { testContentVersion1.Id, testContentVersion2.Id };
		contentDocumentIds = new List<Id> { testContentVersion1.ContentDocumentId, testContentVersion2.ContentDocumentId };

		config = new EnvelopeConfiguration(
			envConfig.Id,
			envConfig.Name,
			envConfig.SourceObject__c,
			UUID.parse(envConfig.DocuSignId__c),
			new List<Document> {
				new EnvelopeConfiguration.TemplateDocument(
					null,
					testContentVersion1.ContentDocumentId,
					1,
					testContentVersion1.Title,
					testContentVersion1.FileExtension,
					false,
					true),
				new EnvelopeConfiguration.TemplateDocument(
					null,
					testContentVersion2.ContentDocumentId,
					1,
					testContentVersion2.Title,
					testContentVersion2.FileExtension,
					false,
					true)
			},
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null);
		EnvelopeConfigurationDocument__c templateDocument1 = TestUtils.createEnvelopeConfigurationDocument(
			testContentVersion1.Title,
			envConfig.Id,
			testContentVersion1.ContentDocumentId,
			EnvelopeConfiguration.DOCUMENT_TYPE_TEMPLATE_DOCUMENT
		);
		System.assertNotEquals(templateDocument1.Id, null);
		EnvelopeConfigurationDocument__c templateDocument2 = TestUtils.createEnvelopeConfigurationDocument(
			testContentVersion2.Title,
			envConfig.Id,
			testContentVersion2.ContentDocumentId,
			EnvelopeConfiguration.DOCUMENT_TYPE_TEMPLATE_DOCUMENT
		);
		System.assertNotEquals(templateDocument2.Id, null);

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			config = new EnvelopeConfiguration(
				envConfig.Id,
				envConfig.Name,
				envConfig.SourceObject__c,
				UUID.parse(envConfig.DocuSignId__c),
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null);
			try {
				EnvelopeConfiguration updatedEnvelopeConfiguration = EnvelopeConfigurationController.updateEnvelopeConfiguration(
					Json.serialize(config),
					false,
					contentDocumentIds);
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeFields_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				EnvelopeConfigurationController.getMergeFields('Opportunity');
				throw new AssertException('Expected getMergeFields to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeFields_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			List<MergeField> result = EnvelopeConfigurationController.getMergeFields('Opportunity');
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
			System.assertNotEquals(null, JSON.serialize(result));
		}
	}

	@IsTest
	static void test_parseEnvelopeConfiguration_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Boolean testResult;
			ContentVersion testContentVersion1 = TestUtils.createContentVersion();
			ContentVersion testContentVersion2 = TestUtils.createContentVersion();
			EnvelopeConfiguration__c envConfig = TestUtils.createEnvelopeConfiguration();
			System.assertNotEquals(envConfig.Id, null);
			System.assertNotEquals(testContentVersion1.ContentDocumentId, null);
			System.assertNotEquals(testContentVersion2.ContentDocumentId, null);
			List<Id> contentVersionIds = new List<Id> { testContentVersion1.Id, testContentVersion2.Id };
			List<Id> contentDocumentIds = new List<Id> { testContentVersion1.ContentDocumentId, testContentVersion2.ContentDocumentId };

			EnvelopeConfiguration config = new EnvelopeConfiguration(
				envConfig.Id,
				envConfig.Name,
				envConfig.SourceObject__c,
				UUID.parse(envConfig.DocuSignId__c),
				new List<Document> {
					new EnvelopeConfiguration.TemplateDocument(
						null,
						testContentVersion1.ContentDocumentId,
						1,
						testContentVersion1.Title,
						testContentVersion1.FileExtension,
						false,
						true),
					new EnvelopeConfiguration.TemplateDocument(
						null,
						testContentVersion2.ContentDocumentId,
						1,
						testContentVersion2.Title,
						testContentVersion2.FileExtension,
						false,
						true)
				},
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				null);
			EnvelopeConfigurationDocument__c templateDocument1 = TestUtils.createEnvelopeConfigurationDocument(
				testContentVersion1.Title,
				envConfig.Id,
				testContentVersion1.ContentDocumentId,
				EnvelopeConfiguration.DOCUMENT_TYPE_TEMPLATE_DOCUMENT
			);
			System.assertNotEquals(templateDocument1.Id, null);
			EnvelopeConfigurationDocument__c templateDocument2 = TestUtils.createEnvelopeConfigurationDocument(
				testContentVersion2.Title,
				envConfig.Id,
				testContentVersion2.ContentDocumentId,
				EnvelopeConfiguration.DOCUMENT_TYPE_TEMPLATE_DOCUMENT
			);
			System.assertNotEquals(templateDocument2.Id, null);
			Test.startTest();
			EnvelopeConfiguration updatedEnvelopeConfiguration =
				EnvelopeConfigurationController.getEnvelopeConfiguration(envConfig.Id);
			Test.stopTest();
			System.assertEquals(updatedEnvelopeConfiguration.documents.size(), 2);
			System.assertEquals([SELECT Id FROM ContentVersion WHERE Id IN:contentVersionIds].size(), 2);
			System.assertEquals([SELECT Id FROM ContentDocument WHERE Id IN:contentDocumentIds].size(), 2);
			System.assertNotEquals(updatedEnvelopeConfiguration.documents[0].size, 0);
		}
	}
}
