@IsTest
private class GenControllerTest {

	@IsTest
	static void test_constructors() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			System.assertNotEquals(null, new GenController());
			System.assertNotEquals(null, new GenController(null));
		}
	}

	@isTest
	static void test_constructor_nonSetupWizard_Edit() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			GenTemplate__c testGenTemplate = new GenTemplate__c(Name = 'TestTemplate', TemplateType__c = 'Online Editor');
			insert testGenTemplate;
			Test.startTest();
			PageReference genTemplateNavigatorPageReference = Page.GenTemplateNavigator;
			Test.setCurrentPageReference(genTemplateNavigatorPageReference);
			genTemplateNavigatorPageReference.getParameters().put('templateId', testGenTemplate.Id);
			genTemplateNavigatorPageReference.getParameters().put('isFromSetupWizard', 'false');
			genTemplateNavigatorPageReference.getParameters().put('isEdit', 'true');
			GenController testController = new GenController();
			System.assertNotEquals(null, testController);
			System.assertEquals(true, testController.editMode);
			System.assertEquals(null, testController.errorMessage);
			System.assertNotEquals(null, testController.templateJson);
			System.assertEquals([SELECT Id, Name from GenTemplate__c LIMIT 1].Name, testController.templateName);
			Test.stopTest();
		}
	}

	@isTest
	static void test_constructor_setupWizard_New() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Test.startTest();
			PageReference genTemplateNavigatorPageReference = Page.GenTemplateNavigator;
			Test.setCurrentPageReference(genTemplateNavigatorPageReference);
			genTemplateNavigatorPageReference.getParameters().put('isFromSetupWizard', 'true');
			genTemplateNavigatorPageReference.getParameters().put('isEdit', 'false');
			GenController testController = new GenController();
			System.assertNotEquals(null, testController);
			System.assertEquals(false, testController.editMode);
			System.assertEquals(false, testController.editMode);
			System.assertEquals(Layout.ACTION_NAME_ONLINEEDITOR, testController.layoutActionName);
			System.assertEquals(Layout.ACTION_TYPE_ONLINEEDITOR, testController.layoutActionType);
			Test.stopTest();
		}
	}

	@isTest
	static void test_constructor_unAuthorized() {
		System.runAs(UserMock.createRestrictedUser()) {
			Test.startTest();
			try {
				GenController testController = new GenController();
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
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
		User adminUser = UserMock.createDocuSignAdministrator(false);
		System.runAs(adminUser) {
			Permissions.assignDocuSignGeneratorPermissionSet(new Set<Id> { adminUser.Id });
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
		User adminUser = UserMock.createDocuSignAdministrator(false);
		System.runAs(adminUser) {
			Permissions.assignDocuSignGeneratorPermissionSet(new Set<Id> { adminUser.Id });
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
		User adminUser = UserMock.createDocuSignAdministrator(false);
		System.runAs(adminUser) {
			Permissions.assignDocuSignGeneratorPermissionSet(new Set<Id> { adminUser.Id });
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
		User adminUser = UserMock.createDocuSignAdministrator(false);
		System.runAs(adminUser) {
			Permissions.assignDocuSignGeneratorPermissionSet(new Set<Id> { adminUser.Id });
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

	@IsTest
	static void test_getSendingDeepLink() {
		System.runAs(UserMock.createDocuSignUser()) {
			Schema.Account a = TestUtils.createAccount();
			String title = UUID.randomUUID().toString();
			String base64Data1 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			String base64Data2 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));
			String base64Data3 = EncodingUtil.base64Encode(Blob.valueOf(UUID.randomUUID().toString()));

			ContentVersion result1 = FileService.saveFile(null, a.Id, title, base64Data1);
			ContentVersion result2 = FileService.saveFile(null, a.Id, title, base64Data2);
			ContentVersion result3 = FileService.saveFile(null, a.Id, title, base64Data3);

			String fileIdsInCommaSeparated = String.Join(new List<String> { result1.ContentDocumentId, result2.ContentDocumentId, result3.ContentDocumentId }, ',');

			Test.startTest();
			Pagereference ref = new PageReference(GenController.getSendingDeepLink(a.Id, fileIdsInCommaSeparated));
			Test.stopTest();

			System.assertEquals((Id)ref.getParameters().get('sid'), a.id);
			System.assertEquals(EncodingUtil.urlDecode(ref.getParameters().get('files'), StringUtils.ENCODING), fileIdsInCommaSeparated);
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
				GenController.getMergeFields('Opportunity');
				throw new AssertException('Expected getMergeFields to fail');
			} catch (Exception ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeFields_success2() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			Test.startTest();
			MergeFieldsResult result = GenController.getMergeFields('Opportunity');
			Test.stopTest();
			System.assert(Collection.isNotEmpty(result.objects));
			System.assertNotEquals(null, JSON.serialize(result));
		}
	}

	@IsTest
	static void test_redirectOnEdit_isEdit() {
		User adminUser = UserMock.createDocuSignAdministrator(false);
		System.runAs(adminUser) {
			Permissions.assignDocuSignGeneratorPermissionSet(new Set<Id> { adminUser.Id });
			Permissions.assignDocuSignNegotiatorPermissionSet(new Set<Id> { adminUser.Id });

			GenTemplate__c template = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			template.TemplateId__c = UUID.randomUUID().toString();
			template.TemplateType__c = Gen.ONLINE_EDITOR_TYPE;
			update template;

			Test.setCurrentPage(Page.OnlineEditorGenTemplate);
			ApexPages.currentPage().getParameters().put('id', template.id);

			Test.startTest();
			GenController controller = new GenController();
			PageReference result2 = controller.redirectOnEdit();
			System.assertEquals(result2.getParameters().get('isEdit'), 'true');
			Test.stopTest();
		}
	}

	@IsTest
	static void test_redirectOnEdit() {
		User adminUser = UserMock.createDocuSignAdministrator(false);
		System.runAs(adminUser) {
			Permissions.assignDocuSignGeneratorPermissionSet(new Set<Id> { adminUser.Id });
			Permissions.assignDocuSignNegotiatorPermissionSet(new Set<Id> { adminUser.Id });

			GenTemplate__c template = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			template.TemplateType__c = Gen.ONLINE_EDITOR_TYPE;
			update template;

			Test.setCurrentPage(Page.OnlineEditorGenTemplate);
			ApexPages.currentPage().getParameters().put('id', template.id);

			Test.startTest();
			GenController controller = new GenController();
			PageReference result1 = controller.redirectOnEdit();
			System.assertEquals(result1.getParameters().get('isEdit'), 'false');
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplateTypes_success() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
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
	static void test_getTemplateTypes_unAuthorized() {
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
	static void test_prepareCancelUrl_success() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			String resultUrl;
			Test.startTest();
			resultUrl = GenController.prepareCancelUrl();
			System.assertEquals(true, String.isNotBlank(resultUrl));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_prepareCancelUrl_unAuthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.prepareCancelUrl();
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_generateUploadToken_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(true)) {
			Test.startTest();
			Negotiate.LimitedAccessToken limitedAccessToken = GenController.generateUploadToken(OnlineEditorRoot__c.getOrgDefaults().FolderId__c);
			Test.stopTest();
			System.assertNotEquals(null, limitedAccessToken);
		}
	}

	@IsTest
	static void test_generateUploadToken_unAuthorized() {
		ScmAPIMock.success();
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.generateUploadToken(UUID.randomUUID().toString());
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_generateDownloadToken_success() {
		ScmAPIMock.success();
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(true)) {
			Test.startTest();
			Negotiate.LimitedAccessToken limitedAccessToken = GenController.generateDownloadToken(OnlineEditorRoot__c.getOrgDefaults().FolderId__c);
			Test.stopTest();
			System.assertNotEquals(null, limitedAccessToken);
		}
	}

	@IsTest
	static void test_generateDownloadToken_unAuthorized() {
		ScmAPIMock.success();
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.generateDownloadToken(UUID.randomUUID().toString());
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignNegotiator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEntityRecords_success() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(true)) {
			TestUtils.createAccount();
			Test.startTest();
			List<SObject> testResultsList = new List<SObject>();
			testResultsList = GenController.getEntityRecords('Account');
			System.assertEquals(1, testResultsList.size());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getEntityRecords_unAuthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.getEntityRecords('Account');
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplateFolderId_success() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(true)) {
			Test.startTest();
			String testTemplateFolderId;
			testTemplateFolderId = GenController.getTemplateFolderId();
			System.assertNotEquals(null, testTemplateFolderId);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplateFolderId_unAuthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.getTemplateFolderId();
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteTemplate_success() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(true)) {
			GenTemplate__c testTemplate = new GenTemplate__c(Name = 'TestTemplate', TemplateType__c = Gen.ONLINE_EDITOR_TYPE, SourceObject__c = 'Account');
			insert testTemplate;
			Test.startTest();
			System.assertEquals(1, [SELECT COUNT() FROM GenTemplate__c]);
			GenController.deleteTemplate(testTemplate.Id);
			Test.stopTest();
			System.assertEquals(0, [SELECT COUNT() FROM GenTemplate__c]);
		}
	}

	@IsTest
	static void test_deleteTemplate_unAuthorized() {
		System.runAs(UserMock.createUser()) {
			GenTemplate__c testTemplate = new GenTemplate__c(Name = 'TestTemplate', TemplateType__c = Gen.ONLINE_EDITOR_TYPE, SourceObject__c = 'Account');
			insert testTemplate;
			Test.startTest();
			try {
				GenController.deleteTemplate(testTemplate.Id);
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getLayouts_success() {
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			List<Layout> testLayouts = new List<Layout>();
			Test.startTest();
			testLayouts = GenController.getLayouts('Contact');
			Test.stopTest();
			System.assert(Collection.isNotEmpty(testLayouts));
		}
	}

	@IsTest
	static void test_getLayouts_unAuthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.getLayouts('Account');
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateLayouts_success() {
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(true)) {
			GenTemplate__c testTemplate = new GenTemplate__c(Name = 'TestTemplate', TemplateType__c = Gen.ONLINE_EDITOR_TYPE, SourceObject__c = 'Account');
			insert testTemplate;
			Layout l1 = new Layout(
				Contact.getSObjectType(),
				UserInfo.getOrganizationId(),
				'ns',
				'n1',
				new List<Layout.Action> {
					new Layout.Action(
						Layout.ACTION_TYPE_ONLINEEDITOR,
						Layout.ACTION_NAME_ONLINEEDITOR,
						'testLabel')
				});
			Layout l2 = new Layout(
				Contact.getSObjectType(),
				UserInfo.getOrganizationId(),
				'ns',
				'n2',
				new List<Layout.Action> {
					new Layout.Action(
						Layout.ACTION_TYPE_ONLINEEDITOR,
						Layout.ACTION_NAME_ONLINEEDITOR,
						'testLabel')
				});

			Test.startTest();
			String layoutJSONString = JSON.serialize(new List<Layout> { l1, l2 });
			String parameters = '{"genButtonApiName":"testOnlineEditorbutton","genButtonLabel":"testOnlineEditorlabel", "genTemplateId":"' + testTemplate.Id + '"}';
			List<Layout> result = GenController.updateLayouts(
				'Contact',
				layoutJSONString,
				parameters);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
		}
	}

	@IsTest
	static void test_updateLayouts_unAuthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.updateLayouts('Account', null, null);
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getSpringTemplateIdInUUIDFormat_success() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			UUID testUUID;
			Test.startTest();
			testUUID = GenController.getSpringTemplateIdInUUIDFormat(UUID.randomUUID().toString());
			Test.stopTest();
			System.assertNotEquals(null, testUUID);
		}
	}

	@IsTest
	static void test_getSpringTemplateIdInUUIDFormat_unAuthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenController.getSpringTemplateIdInUUIDFormat(UUID.randomUUID().toString());
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateTemplate_success() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			GenTemplate__c testTemplate = new GenTemplate__c(Name = 'TestTemplate', TemplateType__c = Gen.ONLINE_EDITOR_TYPE, SourceObject__c = 'Account');
			insert testTemplate;
			System.assertNotEquals(null, testTemplate.Id);
			System.assertEquals('TestTemplate', [SELECT Id, Name FROM GenTemplate__c LIMIT 1].Name);
			System.assertEquals(Gen.ONLINE_EDITOR_TYPE, [SELECT Id, TemplateType__c FROM GenTemplate__c LIMIT 1].TemplateType__c);
			System.assertEquals('Account', [SELECT Id, SourceObject__c FROM GenTemplate__c LIMIT 1].SourceObject__c);
			Gen.Template testTemplateInstance = new Gen.Template(testTemplate.Id, 'UpdatedGenTemplate', 'Contact', Gen.ONLINE_EDITOR_TYPE, null, null, null, null, null, null, null, null, null, null, null, null);
			Test.startTest();
			testTemplateInstance = GenController.updateTemplate(JSON.serialize(testTemplateInstance));
			Test.stopTest();
			System.assertNotEquals(null, testTemplateInstance);
			System.assertEquals('UpdatedGenTemplate', [SELECT Id, Name FROM GenTemplate__c LIMIT 1].Name);
			System.assertEquals('Contact', [SELECT Id, SourceObject__c FROM GenTemplate__c LIMIT 1].SourceObject__c);
		}
	}

	@IsTest
	static void test_updateTemplate_unAuthorized() {
		System.runAs(UserMock.createUser()) {
			Gen.Template testGenTemplate = new Gen.Template(null, 'TestGenTemplate', 'Account', Gen.ONLINE_EDITOR_TYPE, null, null, null, null, null, null, null, null, null, null, null, null);
			Test.startTest();
			try {
				GenController.updateTemplate(JSON.serialize(testGenTemplate));
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveAttachments_success() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			Contact testContact = new Contact(FirstName = 'testContact', LastName = 'test', Email = 'unittest@test.com');
			insert testContact;
			GenTemplate__c testTemplate = new GenTemplate__c(Name = 'TestTemplate', TemplateType__c = Gen.ONLINE_EDITOR_TYPE, SourceObject__c = 'Contact', FileName__c = 'Main', FileSuffix__c = 'Main Data Source');
			insert testTemplate;
			Id testAttachmentId;
			Test.startTest();
			testAttachmentId = GenController.saveAttachments(testContact.Id, 'Test HTML data', testTemplate.Id);
			Test.stopTest();
			System.assertNotEquals(null, testAttachmentId);
		}
	}

	@IsTest
	static void test_saveAttachments_unAuthorized() {
		System.runAs(UserMock.createUser()) {
			Contact testContact = new Contact(FirstName = 'testContact', LastName = 'test', Email = 'unittest@test.com');
			insert testContact;
			GenTemplate__c testTemplate = new GenTemplate__c(Name = 'TestTemplate', TemplateType__c = Gen.ONLINE_EDITOR_TYPE);
			insert testTemplate;
			Test.startTest();
			try {
				GenController.saveAttachments(UserInfo.getUserId(), 'test', UserInfo.getUserId());
				throw new AssertException('Expected to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignGenerator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getOnlineEditorMergeData_success() {
		System.runAs(UserMock.createDocuSignGeneratorAdminUser(false)) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			Contact c1 = TestUtils.createContact(a.Id);
			Contact c2 = TestUtils.createContact(a.Id);
			OpportunityContactRole ocr1 = TestUtils.createOpportunityContactRole(o.Id, c1.Id);
			OpportunityContactRole ocr2 = TestUtils.createOpportunityContactRole(o.Id, c2.Id);

			List<OnlineEditor.Field> onlineEditorFields = new List<OnlineEditor.Field>();
			onlineEditorFields.add(new OnlineEditor.Field('Name', '', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('Account.Name', '', 'String'));

			List<OnlineEditor.Field> onlineEditorFieldsChild2 = new List<OnlineEditor.Field>();
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Contact.Name', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Contact.Email', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Role', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Id', '', 'String'));

			OnlineEditor.Query q = new OnlineEditor.Query('Opportunity', null, onlineEditorFields, new List<OnlineEditor.Query> {
				new OnlineEditor.Query('OpportunityContactRole', 'OpportunityContactRoles', onlineEditorFieldsChild2, null)
			});

			Test.startTest();
			OnlineEditor.Query result = GenController.getOnlineEditorMergeData(o.Id, JSON.serialize(q));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(q.type, result.type);
			System.assertEquals(q.relationship, result.relationship);
			System.assertEquals(q.fields[0].type, result.fields[0].type);
			System.assertEquals(q.fields[0].name, result.fields[0].name);
			System.assertEquals(o.Name, result.fields[0].value);
			System.assertEquals(q.fields[1].type, result.fields[1].type);
			System.assertEquals(q.fields[1].name, result.fields[1].name);
			System.assertEquals(a.Name, result.fields[1].value);
			System.assertEquals(q.children[0].type, result.children[0].type);
			System.assertEquals(q.children[0].relationship, result.children[0].relationship);
			System.assertEquals(q.children[0].fields[0].type, result.children[0].fields[0].type);
			System.assertEquals(q.children[0].fields[0].name, result.children[0].fields[0].name);
			System.assertEquals(q.children[0].children, result.children[0].children);

		}

	}

	@IsTest
	static void test_getMergeData_viewer_success() {
		System.runAs(UserMock.createDocuSignGenerator(false)) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			Contact c1 = TestUtils.createContact(a.Id);
			Contact c2 = TestUtils.createContact(a.Id);
			OpportunityContactRole ocr1 = TestUtils.createOpportunityContactRole(o.Id, c1.Id);
			OpportunityContactRole ocr2 = TestUtils.createOpportunityContactRole(o.Id, c2.Id);

			List<OnlineEditor.Field> onlineEditorFields = new List<OnlineEditor.Field>();
			onlineEditorFields.add(new OnlineEditor.Field('Name', '', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('Account.Name', '', 'String'));

			List<OnlineEditor.Field> onlineEditorFieldsChild2 = new List<OnlineEditor.Field>();
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Contact.Name', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Contact.Email', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Role', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Id', '', 'String'));

			OnlineEditor.Query q = new OnlineEditor.Query('Opportunity', null, onlineEditorFields, new List<OnlineEditor.Query> {
				new OnlineEditor.Query('OpportunityContactRole', 'OpportunityContactRoles', onlineEditorFieldsChild2, null)
			});

			Test.startTest();
			OnlineEditor.Query result = GenController.getOnlineEditorMergeData(o.Id, Json.serialize(q));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(q.type, result.type);
			System.assertEquals(q.relationship, result.relationship);
			System.assertEquals(q.fields[0].type, result.fields[0].type);
			System.assertEquals(q.fields[0].name, result.fields[0].name);
			System.assertEquals(o.Name, result.fields[0].value);
			System.assertEquals(q.fields[1].type, result.fields[1].type);
			System.assertEquals(q.fields[1].name, result.fields[1].name);
			System.assertEquals(a.Name, result.fields[1].value);
			System.assertEquals(q.children[0].type, result.children[0].type);
			System.assertEquals(q.children[0].relationship, result.children[0].relationship);
			System.assertEquals(q.children[0].fields[0].type, result.children[0].fields[0].type);
			System.assertEquals(q.children[0].fields[0].name, result.children[0].fields[0].name);
			System.assertEquals(q.children[0].children, result.children[0].children);

		}
	}

	@IsTest
	static void test_getOnlineEditorMergeData_unAuthorized() {
		System.runAs(UserMock.createUser()) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			Contact c1 = TestUtils.createContact(a.Id);
			Contact c2 = TestUtils.createContact(a.Id);
			OpportunityContactRole ocr1 = TestUtils.createOpportunityContactRole(o.Id, c1.Id);
			OpportunityContactRole ocr2 = TestUtils.createOpportunityContactRole(o.Id, c2.Id);

			List<OnlineEditor.Field> onlineEditorFields = new List<OnlineEditor.Field>();
			onlineEditorFields.add(new OnlineEditor.Field('Name', '', 'String'));
			onlineEditorFields.add(new OnlineEditor.Field('Account.Name', '', 'String'));

			List<OnlineEditor.Field> onlineEditorFieldsChild2 = new List<OnlineEditor.Field>();
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Contact.Name', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Contact.Email', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Role', '', 'String'));
			onlineEditorFieldsChild2.add(new OnlineEditor.Field('Id', '', 'String'));

			OnlineEditor.Query q = new OnlineEditor.Query('Opportunity', null, onlineEditorFields, new List<OnlineEditor.Query> {
				new OnlineEditor.Query('OpportunityContactRole', 'OpportunityContactRoles', onlineEditorFieldsChild2, null)
			});
			OnlineEditor.Query result;
			Test.startTest();
			result = GenController.getOnlineEditorMergeData(o.Id, JSON.serialize(q));
			System.assertNotEquals(null, result);
			System.assertEquals('', result.type);
			System.assertEquals('', result.relationship);
			System.assertEquals(0, result.fields.size());
			System.assertEquals(0, result.children.size());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_redirectOnNewTemplate_OnlineEditor() {
		User adminUser = UserMock.createDocuSignAdministrator(false);
		System.runAs(adminUser) {
			Permissions.assignDocuSignGeneratorPermissionSet(new Set<Id> { adminUser.Id });
			Permissions.assignDocuSignNegotiatorPermissionSet(new Set<Id> { adminUser.Id });

			GenTemplate__c template = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			template.TemplateType__c = Gen.ONLINE_EDITOR_TYPE;
			update template;

			Test.setCurrentPage(Page.GenTemplateNavigator);
			ApexPages.currentPage().getParameters().put('id', template.id);
			PageReference expectedOnlineEditorPage = Page.OnlineEditorGenTemplate ;
			expectedOnlineEditorPage.getParameters().put('id', template.id);
			expectedOnlineEditorPage.getParameters().put('isEdit', 'false');
			expectedOnlineEditorPage.getParameters().put('isFromSetupWizard', 'false');
			Test.startTest();
			GenController controller = new GenController();
			PageReference result = controller.redirectOnNewTemplate();
			System.assertEquals(Salesforce.baseUrl.toExternalForm() + expectedOnlineEditorPage.getUrl(), result.getUrl());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_redirectOnNewTemplate_WordBasedGen() {
		User adminUser = UserMock.createDocuSignAdministrator(false);
		System.runAs(adminUser) {
			Permissions.assignDocuSignGeneratorPermissionSet(new Set<Id> { adminUser.Id });
			Permissions.assignDocuSignNegotiatorPermissionSet(new Set<Id> { adminUser.Id });

			GenTemplate__c template = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			template.TemplateType__c = 'Microsoft Word';
			update template;

			Test.setCurrentPage(Page.GenTemplateNavigator);
			ApexPages.currentPage().getParameters().put('id', template.id);
			PageReference expectedWordBasedGenPage = Page.GenTemplate ;
			expectedWordBasedGenPage.getParameters().put('id', template.id);
			expectedWordBasedGenPage.getParameters().put('isEdit', 'false');
			expectedWordBasedGenPage.getParameters().put('isFromSetupWizard', 'false');
			Test.startTest();
			GenController controller = new GenController();
			PageReference result = controller.redirectOnNewTemplate();
			System.assertEquals(Salesforce.baseUrl.toExternalForm() + expectedWordBasedGenPage.getUrl(), result.getUrl());
			Test.stopTest();
		}
	}

}
