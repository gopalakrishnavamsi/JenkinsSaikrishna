@IsTest
private class GenControllerTest {

	@IsTest
	static void test_constructor_default() {
		PageReference pg = Page.GenDocumentGenerator;
		Test.setCurrentPage(pg);
		Test.startTest();
		GenController result = new GenController();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals('/' + GenTemplate__c.getSObjectType().getDescribe().getKeyPrefix() + '/o', result.objectHomeUrl);
	}

	@IsTest
	static void test_constructor_standard() {
		GenTemplate__c template = new GenTemplate__c(
			Name = UUID.randomUUID().toString(),
			TemplateType__c = Gen.TYPE_WORD);
		insert template;

		Test.startTest();
		new GenController(null);
		GenController result = new GenController(new ApexPages.StandardController(template));
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals('/' + GenTemplate__c.getSObjectType().getDescribe().getKeyPrefix() + '/o', result.objectHomeUrl);
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
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
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
				GenController.getMergeFields('Opportunity', 1);
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
			List<MergeField> result = GenController.getMergeFields('Opportunity', 1);
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
			System.assertNotEquals(null, JSON.serialize(result));
		}
	}

	@IsTest
	static void test_checkDocumentRules_unauthorized_preview() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.checkDocumentRules(UserInfo.getUserId(), 'test', 'test', true);
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeAdministratorOrGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_checkDocumentRules_unauthorized_no_preview() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.checkDocumentRules(UserInfo.getUserId(), 'test', 'test', false);
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_checkDocumentRules_undefined_argument() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			Test.startTest();
			try {
				GenController.checkDocumentRules(null, 'test', 'test', true);
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_checkDocumentRules_matches_true() {
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			ContentVersion cv1 = TestUtils.createGenFile(gt.Id);
			Schema.Account acc = TestUtils.createAccount();

			Test.startTest();
			Gen.Template result = GenService.getTemplate(gt.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, Collection.size(result.generated));
			String testFilesJson = String.valueOf(JSON.serialize(result.generated));
			List<Gen.RuleEvaluation> testEvaluations = GenController.checkDocumentRules(acc.Id, 'Account', testFilesJson, false);
			System.assertEquals(1, Collection.size(testEvaluations));
			System.assertEquals(cv1.ContentDocumentId, testEvaluations.get(0).contentDocumentId);
			System.assertEquals(true, testEvaluations.get(0).matches);
		}
	}

	@IsTest
	static void test_checkDocumentRules_matches_false() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			ContentVersion cv1 = TestUtils.createGenFile(gt.Id);
			Schema.Account acc = TestUtils.createAccountWithName('ANOTHER UNIT TEST');

			Test.startTest();
			Gen.Template result = GenService.getTemplate(gt.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, Collection.size(result.generated));
			String testFilesJson = String.valueOf(JSON.serialize(result.generated));
			List<Gen.RuleEvaluation> testEvaluations = GenController.checkDocumentRules(acc.Id, 'Account', testFilesJson, true);
			System.assertEquals(1, Collection.size(testEvaluations));
			System.assertEquals(cv1.ContentDocumentId, testEvaluations.get(0).contentDocumentId);
			System.assertEquals(false, testEvaluations.get(0).matches);
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
				System.assertEquals(Label.MustBeAdministratorOrGenerator, ex.getMessage());
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
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getLatestRecordId_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
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
				System.assertEquals(Label.MustBeAdministratorOrGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeData_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Schema.Account a = TestUtils.createAccount();

			Contact ct1 = TestUtils.createContact(a.Id);
			Contact ct2 = TestUtils.createContact(a.Id);

			Opportunity o1 = new Opportunity(AccountId = a.Id, Name = 'UNIT TEST 10', CloseDate = Date.today(), StageName = 'Negotiation/Review');
			Opportunity o2 = new Opportunity(AccountId = a.Id, Name = 'UNIT TEST 11', CloseDate = Date.today(), StageName = 'Negotiation/Review');
			Opportunity o3 = new Opportunity(AccountId = a.Id, Name = 'UNIT TEST 20', CloseDate = Date.today(), StageName = 'Negotiation/Review');
			insert new List<Opportunity> { o1, o2, o3 };

			Case cs1 = new Case(AccountId = a.Id, ContactId = ct1.Id);
			Case cs2 = new Case(AccountId = a.Id, ContactId = ct2.Id);
			insert new List<Case> { cs1, cs2 };

			Query q = Query.newQuery(
				'Account',
				new List<String> { 'Name', 'Owner.Name' },
				new List<Query> {
					Query.newSubQuery(
						'Contact',
						new List<String> { 'Name' },
						'Contacts',
						null,
						'Name DESC',
						100,
						new List<Query> {
							Query.newChildQuery(
								'Case',
								new List<String> { 'CaseNumber' },
								'Cases',
								'ContactId',
								null,
								null,
								100)
						}),
					Query.newSubQuery(
						'Opportunity',
						new List<String> { 'Name' },
						'Opportunities',
						'Name LIKE \'UNIT TEST 1%\'',
						null,
						null,
						null)
				});

			Test.startTest();
			Query.Result result = GenController.getMergeData(a.Id, JSON.serialize(q));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.result);
			System.assert(result.result instanceof Schema.Account);
			Schema.Account aa = (Schema.Account)result.result;
			System.assertEquals(2, Collection.size(aa.Opportunities));
			System.assertEquals(2, Collection.size(aa.Contacts));
			System.assertNotEquals(null, aa.Owner);
			System.assertEquals(UserInfo.getName(), aa.Owner.Name);

			System.assertNotEquals(null, result.children);
			System.assertEquals(1, result.children.size());
			System.assertEquals(2, Collection.size(result.children.get('Cases')));
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
				System.assertEquals(Label.MustBeAdministratorOrGenerator, ex.getMessage());
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
				System.assertEquals(Label.MustBeAdministratorOrGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteContentDocument_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
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
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveChunk_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
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
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getSendingDeepLink_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			String title = UUID.randomUUID().toString();
			String base64Data1 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			String base64Data2 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			String base64Data3 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));

			ContentVersion result1 = FileService.saveFile(null, a.Id, title, base64Data1);
			ContentVersion result2 = FileService.saveFile(null, a.Id, title, base64Data2);
			ContentVersion result3 = FileService.saveFile(null, a.Id, title, base64Data3);

			String scmFile1 = 'scm;' + UUID.randomUUID() + ';UnitTestScmFile1;html';
			String scmFile2 = 'scm;' + UUID.randomUUID() + ';UnitTestScmFile2;html';

			List<String> files = new List<String> {
				result1.ContentDocumentId, result2.ContentDocumentId,
				result3.ContentDocumentId, scmFile1, scmFile2
			};

			Test.startTest();
			String result = GenController.getSendingDeepLink(a.Id, files);
			Test.stopTest();

			System.assert(String.isNotBlank(result));
		}
	}

	@IsTest
	static void test_getSendingDeepLink_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.getSendingDeepLink(null, null);
				throw new AssertException('Expected getSendingDeepLink to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createAgreementInEOSFolder_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.createAgreementInEOSFolder(UserInfo.getUserId(), UserInfo.getUserId(), 'testName');
				throw new AssertException('Expected createAgreementInEOSFolder to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createAgreementInEOSFolder_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator(true)) {
			NegotiateAPI.TaskStatus testTaskStatus;
			Test.startTest();
			testTaskStatus = GenController.createAgreementInEOSFolder(UserInfo.getUserId(), UserInfo.getUserId(), 'testName');
			Test.stopTest();
			System.assertNotEquals(null, testTaskStatus);
		}
	}

	@IsTest
	static void test_getAgreement_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.getAgreement(ScmAPIMock.DOCUMENT_ID_2.value);
				throw new AssertException('Expected get Agreement to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getAgreement_success() {
		ScmAPIMock.success();

		System.runAs(UserMock.createDocuSignNegotiator(true)) {

			Test.startTest();
			Agreement agreement = GenController.getAgreement(ScmAPIMock.DOCUMENT_ID_2.value);
			Test.stopTest();
			System.assertNotEquals(null, agreement);
		}
	}

	@IsTest
	static void test_getMergeFields_failure2() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenController.getMergeFields('Opportunity', 1);
				throw new AssertException('Expected getMergeFields to fail');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeFields_success2() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			List<MergeField> result = GenController.getMergeFields('Opportunity', 1);
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
		}
	}

	@IsTest
	static void test_redirectOnEdit_word() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			GenTemplate__c template = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			template.TemplateType__c = Gen.TYPE_WORD;
			update template;

			PageReference pg = Page.GenTemplateNavigator;
			Test.setCurrentPage(pg);
			pg.getParameters().put('templateId', template.Id);

			Test.startTest();
			GenController controller = new GenController(new ApexPages.StandardController(template));
			PageReference result1 = controller.redirectOnEdit();
			System.assertEquals(result1.getParameters().get('isEdit'), 'true');
			Test.stopTest();
		}
	}

	@IsTest
	static void test_redirectOnEdit_isEdit() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			GenTemplate__c template = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			template.TemplateId__c = UUID.randomUUID().toString();
			template.TemplateType__c = Gen.TYPE_ONLINE;
			update template;

			PageReference pg = Page.GenTemplateNavigator;
			Test.setCurrentPage(pg);
			pg.getParameters().put('templateId', template.Id);

			Test.startTest();
			GenController controller = new GenController(new ApexPages.StandardController(template));
			PageReference result2 = controller.redirectOnEdit();
			System.assertEquals(result2.getParameters().get('isEdit'), 'true');
			Test.stopTest();
		}
	}

	@IsTest
	static void test_redirectOnEdit() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			GenTemplate__c template = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			template.TemplateType__c = Gen.TYPE_ONLINE;
			update template;

			PageReference pg = Page.GenTemplateNavigator;
			Test.setCurrentPage(pg);
			pg.getParameters().put('templateId', template.Id);

			Test.startTest();
			GenController controller = new GenController(new ApexPages.StandardController(template));
			controller.templateId = template.Id;
			PageReference result1 = controller.redirectOnEdit();
			System.assertEquals(result1.getParameters().get('isEdit'), 'false');
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplateTypes_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Map<String, String> testTemplateTypesMap = new Map<String, String>();
			Test.startTest();
			testTemplateTypesMap = GenController.getTemplateTypes();
			Test.stopTest();
			System.assertEquals(false, testTemplateTypesMap.isEmpty());
			System.assertEquals(2, testTemplateTypesMap.size());
			System.assertEquals(true, testTemplateTypesMap.containsKey('Microsoft Word'));
			System.assertEquals(true, testTemplateTypesMap.containsKey('Online Editor'));
		}
	}

	@IsTest
	static void test_getTemplateTypes_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.getTemplateTypes();
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_redirectOnNewTemplate_online() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			GenTemplate__c template = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			template.TemplateType__c = Gen.TYPE_ONLINE;
			update template;

			Test.startTest();
			GenController controller = new GenController(new ApexPages.StandardController(template));
			controller.templateId = template.Id;
			PageReference result = controller.redirectOnNewTemplate();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.getUrl().toLowerCase().contains(Application.namespacePrefix + 'onlineeditorgentemplate'));
			System.assertEquals(template.Id, (Id)result.getParameters().get('id'));
			System.assertEquals('false', result.getParameters().get('isEdit'));
			System.assertEquals('false', result.getParameters().get('isFromSetupWizard'));
		}
	}

	@IsTest
	static void test_redirectOnNewTemplate_word() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			GenTemplate__c template = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			template.TemplateType__c = Gen.TYPE_WORD;
			update template;

			Test.startTest();
			GenController controller = new GenController(new ApexPages.StandardController(template));
			controller.templateId = template.Id;
			PageReference result = controller.redirectOnNewTemplate();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.getUrl().toLowerCase().contains(Application.namespacePrefix + 'gentemplate'));
			System.assertEquals(template.Id, (Id)result.getParameters().get('id'));
			System.assertEquals('false', result.getParameters().get('isEdit'));
			System.assertEquals('false', result.getParameters().get('isFromSetupWizard'));
		}
	}

	@IsTest
	static void test_deleteTemplate_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Lead.getSObjectType());
			gt.TemplateId__c = String.valueOf(ScmAPIMock.DOCUMENT_ID);
			gt.TemplateType__c = Gen.TYPE_ONLINE;
			update gt;
			Test.startTest();
			Boolean isDeleted = GenController.deleteTemplate(gt.Id);
			System.assertEquals(isDeleted, true);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_redirectOnEdit_Unauthorized() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			GenTemplate__c template = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			template.TemplateType__c = Gen.TYPE_WORD;
			update template;
			GenController controller = new GenController(new ApexPages.StandardController(template));

			Test.startTest();
			controller.redirectOnEdit();
			Test.stopTest();

			System.assertEquals(controller.errorMessage, Label.MustBeDocuSignAdministrator);
		}
	}

	@IsTest
	static void test_deleteTemplate_unauthorized() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Lead.getSObjectType());
			gt.TemplateId__c = String.valueOf(ScmAPIMock.DOCUMENT_ID);
			gt.TemplateType__c = Gen.TYPE_ONLINE;
			update gt;
			Test.startTest();
			try {
				GenController.deleteTemplate(gt.Id);
				throw new AssertException('Expected delete template to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_redirectOnNewTemplate_Unauthorized() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			GenTemplate__c template = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			template.TemplateType__c = Gen.TYPE_WORD;
			update template;

			PageReference expectedWordBasedGenPage = Page.GenTemplate;
			expectedWordBasedGenPage.getParameters().put('id', template.Id);
			expectedWordBasedGenPage.getParameters().put('isEdit', 'false');
			expectedWordBasedGenPage.getParameters().put('isFromSetupWizard', 'false');

			GenController controller = new GenController(new ApexPages.StandardController(template));
			controller.templateId = template.Id;

			Test.startTest();
			controller.redirectOnNewTemplate();
			Test.stopTest();

			System.assertEquals(controller.errorMessage, Label.MustBeDocuSignAdministrator);
		}
	}

	@IsTest
	static void test_getTempEOSFolderId_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			TestUtils.createAgreementConfiguration(ScmAPIMock.SOURCE_OBJECT_ID, ScmAPIMock.FOLDER_ID.toString(), null);
			Test.startTest();
			UUID eosFolderId = GenController.getTempEOSFolderId(ScmAPIMock.SOURCE_OBJECT_ID);
			System.assert(eosFolderId != null);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTempEOSFolderId_unauthorized() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser(true)) {
			TestUtils.createAgreementConfiguration(ScmAPIMock.SOURCE_OBJECT_ID, ScmAPIMock.FOLDER_ID.toString(), null);
			Test.startTest();
			try {
				GenController.getTempEOSFolderId(ScmAPIMock.SOURCE_OBJECT_ID);
				throw new AssertException('Expected get EOSFolderId to Fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_convertHtmlDocumentToWord_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			Test.startTest();
			GenController.convertHtmlDocumentToWord(String.valueOf(ScmAPIMock.DOCUMENT_ID));
			system.assert(true);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_convertHtmlDocumentToWord_unauthorized() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser(true)) {
			Test.startTest();
			try {
				GenController.convertHtmlDocumentToWord(String.valueOf(ScmAPIMock.DOCUMENT_ID));
				throw new AssertException('Expected convertHtmlDocumentToWord to Fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteDocument_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator(true)) {
			Test.startTest();
			system.assert(GenController.deleteDocument(String.valueOf(ScmAPIMock.DOCUMENT_ID)));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteScmDocument_unauthorized() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser(true)) {
			Test.startTest();
			try {
				GenController.deleteDocument(String.valueOf(ScmAPIMock.DOCUMENT_ID));
				throw new AssertException('Expected deleteScmDocument to Fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_generateLimitedAccessToken_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignGenerator()) {
			UUID entityId = UUID.randomUUID();

			Test.startTest();
			LimitedAccessToken limitedAccessToken = GenController.generateLimitedAccessToken(String.valueOf(entityId));
			Test.stopTest();
			System.assertNotEquals(null, limitedAccessToken);

		}
	}

	@IsTest
	static void test_validateChildRelationshipField_success() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			String fieldJSON = '{"type":"CHILD_RELATIONSHIP","scale":0,"relationship":"Opportunities","relatesTo":"Opportunity","parentIdField":"AccountId","orderBy":"Name ASC","name":"Opportunity","matchType":null,"label":"Opportunities","isConditional":false,"isChildRelation":true,"format":null,"filterBy":"StageName != \'Closed Won\'","conditionalValue":null}';
			String sourceObject = 'Account';

			AuraHandledException expMessage;

			Test.startTest();
			try {
				GenController.validateChildRelationshipField(fieldJSON, 2);
			} catch (AuraHandledException exp) {
				expMessage = exp;
			}
			Test.stopTest();

			System.assertEquals(expMessage, null);
		}
	}

	@IsTest
	static void test_validateChildRelationshipField_failure() {
		System.runAs(UserMock.createDocuSignAdministrator(true)) {
			String fieldJSON = '{"type":"CHILD_RELATIONSHIP","scale":0,"relationship":"Opportunities","relatesTo":"Opportunity","parentIdField":"AccountId","orderBy":"Name ASC","name":"Opportunity","matchType":null,"label":"Opportunities","isConditional":false,"isChildRelation":true,"format":null,"filterBy":"BAD SOQL VALUE","conditionalValue":null}';
			String sourceObject = 'Account';

			AuraHandledException expMessage;

			Test.startTest();
			try {
				GenController.validateChildRelationshipField(fieldJSON, 2);
			} catch (AuraHandledException exp) {
				expMessage = exp;
			}
			Test.stopTest();

			System.assertNotEquals(expMessage, null);
		}
	}

	@IsTest
	static void test_generateLimitedAccessToken_unauthorized() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			UUID entityId = UUID.randomUUID();

			Test.startTest();
			try {
				GenController.generateLimitedAccessToken(String.valueOf(entityId));
				throw new AssertException('Expected generateLimitedAccessToken to Fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getFileName_mainDataSource_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			GenTemplate__c gtx = TestUtils.createGenTemplate(Opportunity.getSObjectType());
			gtx.FileName__c = 'Test,File:Name';
			gtx.FileSuffix__c = 'Main Data Source Name';
			update gtx;

			Test.startTest();
			String fileName = GenController.getFileName(gtx.Id, 'Test/Opportunity');
			Test.stopTest();

			System.assert(fileName.contains('Test_Opportunity'));
			System.assertEquals('Test_File_Name Test_Opportunity', fileName);

		}
	}

	@IsTest
	static void test_getFileName_date_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			GenTemplate__c gtx = TestUtils.createGenTemplate(Opportunity.getSObjectType());
			gtx.FileName__c = 'Test,File:Name';
			gtx.FileSuffix__c = 'Date';
			update gtx;

			Test.startTest();
			String fileName = GenController.getFileName(gtx.Id, 'Test/Opportunity');
			Test.stopTest();

			System.assert(!fileName.contains('Test_Opportunity'));
		}
	}

	@IsTest
	static void test_getFileName_mainDataSourceAndDate_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			GenTemplate__c gtx = TestUtils.createGenTemplate(Opportunity.getSObjectType());
			gtx.FileName__c = 'Test,File:Name';
			gtx.FileSuffix__c = 'Main Data Source Name and Date';
			update gtx;

			Test.startTest();
			String fileName = GenController.getFileName(gtx.Id, 'Test/Opportunity');
			Test.stopTest();

			System.assert(fileName.contains('Test_Opportunity'));
		}
	}

	@IsTest
	static void test_getFileName_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			GenTemplate__c gtx = TestUtils.createGenTemplate(Opportunity.getSObjectType());
			gtx.FileName__c = 'Test,File:Name';
			gtx.FileSuffix__c = 'Main Data Source Name';
			update gtx;

			Test.startTest();
			try {
				GenController.getFileName(gtx.Id, 'Test/Opportunity');
				throw new AssertException('Expected getFileName to Fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeAdministratorOrGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

}
