@IsTest
private class GenControllerTest {

	@IsTest
	static void test_constructors() {
		System.assertNotEquals(null, new GenController());
		System.assertNotEquals(null, new GenController(null));
	}

	@IsTest
	static void test_clone_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenController.clone(null);
				throw new AssertException('Expected clone to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_clone_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Opportunity.getSObjectType());

			Test.startTest();
			Gen.Template result = GenController.clone(gt.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, JSON.serialize(result));
		}
	}

	@IsTest
	static void test_getConfiguration_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.getConfiguration(null);
				throw new AssertException('Expected getConfiguration to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getConfiguration_blank_template() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			GenController.Configuration result = GenController.getConfiguration(null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.template);
			System.assertNotEquals(null, result.template.id);
			System.assert(Collection.isNotEmpty(result.commonObjects));
			System.assert(Collection.isNotEmpty(result.allObjects));
			System.assertEquals(UserInfo.isMultiCurrencyOrganization(), result.isMultiCurrencyOrganization);
			System.assertNotEquals(null, JSON.serialize(result));
		}
	}

	@IsTest
	static void test_getConfiguration_existing_template() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Opportunity.getSObjectType());

			Test.startTest();
			GenController.Configuration result = GenController.getConfiguration(gt.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.template);
			System.assertEquals(gt.Id, result.template.id);
			System.assert(Collection.isNotEmpty(result.commonObjects));
			System.assert(Collection.isNotEmpty(result.allObjects));
			System.assertEquals(UserInfo.isMultiCurrencyOrganization(), result.isMultiCurrencyOrganization);
			System.assertNotEquals(null, JSON.serialize(result));
		}
	}

	@IsTest
	static void test_getMergeFields_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenController.getMergeFields('Opportunity', false);
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
			List<MergeField> result = GenController.getMergeFields('Opportunity', false);
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
			System.assertNotEquals(null, JSON.serialize(result));
		}
	}

	@IsTest
	static void test_saveTemplate_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenController.saveTemplate('null');
				throw new AssertException('Expected saveTemplate to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	private static Gen.Template createGenTemplate() {
		GenTemplate__c gtx = TestUtils.createGenTemplate(Opportunity.getSObjectType());
		Gen.File gf = GenService.DB.convert(TestUtils.createGenFile(gtx.Id));
		return GenService.DB.convert(gtx, new List<Gen.File> { gf });
	}

	@IsTest
	static void test_saveTemplate_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Gen.Template gt = createGenTemplate();

			Test.startTest();
			Gen.Template result = GenController.saveTemplate(JSON.serialize(gt));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, JSON.serialize(result));
		}
	}

	@IsTest
	static void test_getTemplate_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenController.getTemplate(null);
				throw new AssertException('Expected getTemplate to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplate_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Gen.Template gt = createGenTemplate();

			Test.startTest();
			Gen.Template result = GenController.getTemplate(gt.id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(gt.id, result.id);
			System.assertNotEquals(null, JSON.serialize(result));
		}
	}

	@IsTest
	static void test_getLatestRecordId_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenController.getLatestRecordId('Opportunity');
				throw new AssertException('Expected getLatestRecordId to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getLatestRecordId_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Opportunity o = TestUtils.createOpportunity();

			Test.startTest();
			Id result = GenController.getLatestRecordId('Opportunity');
			Test.stopTest();

			System.assertEquals(o.Id, result);
		}
	}

	@IsTest
	static void test_getMergeData_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenController.getMergeData(null, 'null');
				throw new AssertException('Expected getMergeData to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeData_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			Contact c = TestUtils.createContact(a.Id);
			TestUtils.createOpportunityContactRole(o.Id, c.Id);
			Gen.Query q = new Gen.Query(
				'Opportunity',
				null,
				new List<String> { 'Name', 'Account.Name' },
				new List<Gen.Query> {
					new Gen.Query(
						'OpportunityContactRole',
						'OpportunityContactRoles',
						new List<String> { 'Contact.Name', 'Contact.Email', 'Role' },
						null)
				});

			Test.startTest();
			SObject result = GenController.getMergeData(o.Id, JSON.serialize(q));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(o.Id, result.Id);
			System.assertNotEquals(null, JSON.serialize(result));
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenController.queueDocumentGeneration(null, null, null, false, null);
				throw new AssertException('Expected queueDocumentGeneration to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator()) {
			Opportunity o = TestUtils.createOpportunity();
			GenTemplate__c gt = TestUtils.createGenTemplate(Opportunity.getSObjectType());
			ContentVersion cv = TestUtils.createGenFile(gt.Id);

			Test.startTest();
			List<Gen.Job> result = GenController.queueDocumentGeneration(
				gt.Id,
				o.Id,
				'<xml/>',
				false,
				new List<Id> { cv.ContentDocumentId });
			Test.stopTest();

			System.assertEquals(1, Collection.size(result));
			System.assertNotEquals(null, JSON.serialize(result));
		}
	}

	@IsTest
	static void test_getJobStatus_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenController.getJobStatus(null);
				throw new AssertException('Expected getJobStatus to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getJobStatus_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator()) {
			Test.startTest();
			List<Gen.Job> result = GenController.getJobStatus(new List<String> {
				UUID.randomUUID().toString(),
				UUID.randomUUID().toString()
			});
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, JSON.serialize(result));
		}
	}

	@IsTest
	static void test_checkMultiCurrency_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Boolean testResult;
			Test.startTest();
			testResult = GenController.checkMultiCurrency();
			Test.stopTest();

			System.assertNotEquals(null, testResult);
		}
	}

	@IsTest
	static void test_checkMultiCurrency_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenController.checkMultiCurrency();
				throw new AssertException('Expected checkMultiCurrency to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteContentDocument_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Boolean testResult;
			ContentVersion testContentVersion = TestUtils.createContentVersion();
			Test.startTest();
			testResult = GenController.deleteContentDocument(testContentVersion.Id);
			Test.stopTest();

			System.assertNotEquals(null, testResult);
			System.assertEquals(true, testResult);
		}
	}

	@IsTest
	static void test_deleteContentDocument_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			ContentVersion testContentVersion = TestUtils.createContentVersion();
			Test.startTest();
			try {
				GenController.deleteContentDocument(testContentVersion.Id);
				throw new AssertException('Expected deleteContentDocument to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveChunk_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Schema.Account a = TestUtils.createAccount();
			System.assertNotEquals(null, a.Id);
			ContentVersion testContentVersion = TestUtils.createContentVersion(a.Id);
			System.assertNotEquals(null, testContentVersion.Id);
			System.assertNotEquals(null, testContentVersion.Title);

			Test.startTest();
			Gen.File testGenFile = GenController.saveChunk(testContentVersion.Id, a.Id, testContentVersion.Title, 'Test');
			Test.stopTest();

			System.assertNotEquals(null, testGenFile);
		}
	}

	@IsTest
	static void test_saveChunk_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Schema.Account a = TestUtils.createAccount();
			System.assertNotEquals(null, a.Id);
			ContentVersion testContentVersion = TestUtils.createContentVersion(a.Id);
			System.assertNotEquals(null, testContentVersion.Id);
			System.assertNotEquals(null, testContentVersion.Title);
			Test.startTest();
			try {
				GenController.saveChunk(testContentVersion.Id, a.Id, testContentVersion.Title, 'Test');
				throw new AssertException('Expected saveChunk to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}
}
