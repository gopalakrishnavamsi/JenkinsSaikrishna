@IsTest
private class GenServiceTest {

	@IsTest
	static void test_Database_queryRecentRecordIds() {
		Lead l1 = TestUtils.createLead();
		Lead l2 = TestUtils.createLead();

		Test.startTest();
		List<Id> result = GenService.DB.queryRecentRecordIds(Lead.getSObjectType(), 2);
		Test.stopTest();

		System.assertEquals(2, Collection.size(result));
		System.assertEquals(new Set<Id> { l1.Id, l2.Id }, new Set<Id>(result));
	}

	@IsTest
	static void test_clone_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.clone(null);
				throw new AssertException('Expected clone to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_clone_undefined_id() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				GenService.clone(null);
				throw new AssertException('Expected clone to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedId, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_clone_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			GenTemplate__c t = TestUtils.createGenTemplate(Contact.getSObjectType());
			ContentVersion cv1 = TestUtils.createGenFile(t.Id);
			ContentVersion cv2 = TestUtils.createGenFile(t.Id);

			Test.startTest();
			Gen.Template result = GenService.clone(t.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertNotEquals(t.Id, result.id);
			System.assertEquals(String.format(Label.GenTemplateCopyName_2, new List<String> {
				t.Name, '1'
			}), result.name);
			System.assertEquals(t.SourceObject__c, result.sourceObject);
			System.assertNotEquals(null, result.objectMappings);
			System.assertNotEquals(null, result.signerMappings);
			System.assertEquals(t.UseAllTemplates__c, result.useAllTemplates);
			System.assertEquals(t.UseCurrentRecord__c, result.useCurrentRecord);
			System.assertEquals(t.HasPreviewedDocuments__c, result.hasPreviewedDocuments);
			System.assertEquals(t.StepsCompleted__c, result.stepsCompleted);
			System.assertEquals(t.IsSample__c, result.isSample);
			System.assertEquals(2, Collection.size(result.generated));
			for (Gen.File f : result.generated) {
				System.assertNotEquals(null, f.id);
				ContentVersion cv = null;
				if (f.title == cv1.Title) {
					cv = cv1;
				} else if (f.title == cv2.Title) {
					cv = cv2;
				} else {
					throw new AssertException('Unexpected content version in cloned template: ' + f.title);
				}
				System.assertNotEquals(cv.Id, f.id);
				System.assertEquals(cv.Title, f.title);
				System.assertEquals(cv.FileExtension, f.extension);
				System.assertEquals(cv.ContentSize, f.size);
				System.assertEquals(cv.GeneratedFileFormat__c, f.generatedFormat);
				System.assertEquals(cv.GeneratedFileName__c, f.generatedName);
				System.assertEquals(cv.GeneratedFileSuffix__c, f.generatedSuffix);
			}
			System.assertEquals(2, Collection.size([SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :result.id LIMIT 10]));
		}
	}

	@IsTest
	static void test_createBlankTemplate_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.createBlankTemplate();
				throw new AssertException('Expected createBlankTemplate to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createBlankTemplate_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			Gen.Template result = GenService.createBlankTemplate();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.id);
			System.assertEquals(Label.Untitled, result.name);
			System.assertEquals(null, result.sourceObject);
			System.assert(Collection.isEmpty(result.objectMappings));
			System.assert(Collection.isEmpty(result.signerMappings));
			System.assert(result.useAllTemplates);
			System.assert(result.useCurrentRecord);
			System.assert(!result.hasPreviewedDocuments);
			System.assertEquals(0, result.stepsCompleted);
			System.assert(Collection.isEmpty(result.generated));
			GenTemplate__c gt = [
				SELECT Id, Name, SourceObject__c, ObjectMappings__c, SignerMappings__c, UseAllTemplates__c,
					UseCurrentRecord__c, HasPreviewedDocuments__c, StepsCompleted__c, IsSample__c
				FROM GenTemplate__c
				WHERE Id = :result.id
				LIMIT 1
			];
			System.assertEquals(result.name, gt.Name);
			System.assertEquals(result.sourceObject, gt.SourceObject__c);
			System.assertEquals(null, gt.ObjectMappings__c);
			System.assertEquals(null, gt.SignerMappings__c);
			System.assertEquals(result.useAllTemplates, gt.UseAllTemplates__c);
			System.assertEquals(result.useCurrentRecord, gt.UseCurrentRecord__c);
			System.assertEquals(result.hasPreviewedDocuments, gt.HasPreviewedDocuments__c);
			System.assertEquals(result.stepsCompleted, gt.StepsCompleted__c);
		}
	}

	@IsTest
	static void test_getTemplate_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenService.getTemplate(null);
				throw new AssertException('Expected getTemplate to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplate_undefined_id() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				GenService.getTemplate(null);
				throw new AssertException('Expected getTemplate to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedId, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getTemplate_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Lead.getSObjectType());
			ContentVersion cv1 = TestUtils.createGenFile(gt.Id);
			ContentVersion cv2 = TestUtils.createGenFile(gt.Id);

			Test.startTest();
			Gen.Template result = GenService.getTemplate(gt.Id);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(gt.Id, result.id);
			System.assertEquals(gt.Name, result.name);
			System.assertEquals(gt.SourceObject__c, result.sourceObject);
			System.assertEquals(gt.UseAllTemplates__c, result.useAllTemplates);
			System.assertEquals(gt.UseCurrentRecord__c, result.useCurrentRecord);
			System.assertEquals(gt.HasPreviewedDocuments__c, result.hasPreviewedDocuments);
			System.assertEquals(gt.IsSample__c, result.isSample);
			System.assertEquals(2, Collection.size(result.generated));

			Boolean foundCV1 = false, foundCV2 = false;
			for (Gen.File f : result.generated) {
				System.assertNotEquals(null, f);
				if (f.id == cv1.Id) {
					foundCV1 = true;
					System.assertEquals(cv1.Title, f.title);
					System.assertEquals(cv1.FileExtension, f.extension);
					System.assertEquals(cv1.ContentSize, f.size);
					System.assertEquals(cv1.GeneratedFileFormat__c, f.generatedFormat);
					System.assertEquals(cv1.GeneratedFileName__c, f.generatedName);
					System.assertEquals(cv1.GeneratedFileSuffix__c, f.generatedSuffix);
				} else if (f.id == cv2.Id) {
					foundCV2 = true;
					System.assertEquals(cv2.Title, f.title);
					System.assertEquals(cv2.FileExtension, f.extension);
					System.assertEquals(cv2.ContentSize, f.size);
					System.assertEquals(cv2.GeneratedFileFormat__c, f.generatedFormat);
					System.assertEquals(cv2.GeneratedFileName__c, f.generatedName);
					System.assertEquals(cv2.GeneratedFileSuffix__c, f.generatedSuffix);
				} else {
					throw new AssertException('Unexpected generated file: ' + f.generatedName);
				}
			}
			System.assert(foundCV1 && foundCV2);
		}
	}

	@IsTest
	static void test_saveTemplate_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.saveTemplate(null);
				throw new AssertException('Expected saveTemplate to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveTemplate_undefined_template() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				GenService.saveTemplate(null);
				throw new AssertException('Expected saveTemplate to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveTemplate_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			GenTemplate__c gtt = TestUtils.createGenTemplate(Schema.Account.getSObjectType());
			gtt.Name = TestUtils.randomString(12);
			gtt.SourceObject__c = 'Opportunity';
			gtt.UseCurrentRecord__c = false;
			gtt.UseAllTemplates__c = false;
			ContentVersion cv1 = TestUtils.createGenFile(gtt.Id);
			cv1.GeneratedFileName__c = TestUtils.randomString(20);
			ContentVersion cv2 = TestUtils.createGenFile(gtt.Id);
			cv2.GeneratedFileSuffix__c = 'name_date';
			cv2.GeneratedFileFormat__c = 'PDF';
			Gen.Template gt = GenService.DB.convert(gtt, new List<Gen.File> {
				GenService.DB.convert(cv1),
				GenService.DB.convert(cv2)
			});

			Test.startTest();
			Gen.Template result = GenService.saveTemplate(gt);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(gt.id, result.id);
			System.assertEquals(gt.name, result.name);
			System.assertEquals(gt.sourceObject, result.sourceObject);
			System.assertEquals(gt.useAllTemplates, result.useAllTemplates);
			System.assertEquals(gt.useCurrentRecord, result.useCurrentRecord);
			System.assertEquals(gt.hasPreviewedDocuments, result.hasPreviewedDocuments);
			System.assertEquals(gt.isSample, result.isSample);
			System.assertEquals(2, Collection.size(result.generated));

			Boolean foundCV1 = false, foundCV2 = false;
			for (Gen.File f : result.generated) {
				System.assertNotEquals(null, f);
				if (f.id == cv1.Id) {
					foundCV1 = true;
					System.assertEquals(cv1.Title, f.title);
					System.assertEquals(cv1.FileExtension, f.extension);
					System.assertEquals(cv1.ContentSize, f.size);
					System.assertEquals(cv1.GeneratedFileFormat__c, f.generatedFormat);
					System.assertEquals(cv1.GeneratedFileName__c, f.generatedName);
					System.assertEquals(cv1.GeneratedFileSuffix__c, f.generatedSuffix);
				} else if (f.id == cv2.Id) {
					foundCV2 = true;
					System.assertEquals(cv2.Title, f.title);
					System.assertEquals(cv2.FileExtension, f.extension);
					System.assertEquals(cv2.ContentSize, f.size);
					System.assertEquals(cv2.GeneratedFileFormat__c, f.generatedFormat);
					System.assertEquals(cv2.GeneratedFileName__c, f.generatedName);
					System.assertEquals(cv2.GeneratedFileSuffix__c, f.generatedSuffix);
				} else {
					throw new AssertException('Unexpected generated file: ' + f.generatedName);
				}
			}
			System.assert(foundCV1 && foundCV2);
		}
	}

	@IsTest
	static void test_getRecentRecords_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenService.getRecentRecordIds(null, 0);
				throw new AssertException('Expected getRecentRecordIds to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getRecentRecords_undefined_type() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.getRecentRecordIds(null, 0);
				throw new AssertException('Expected getRecentRecordIds to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getRecentRecords_success() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Lead l1 = TestUtils.createLead();
			Lead l2 = TestUtils.createLead();

			Test.startTest();
			List<Id> result = GenService.getRecentRecordIds(Lead.getSObjectType(), 2);
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertEquals(new Set<Id> { l2.Id, l1.Id }, new Set<Id>(result));
		}
	}

	@IsTest
	static void test_getMergeData_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenService.getMergeData(null, null);
				throw new AssertException('Expected getMergeData to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeData_undefined_argument() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.getMergeData(null, null);
				throw new AssertException('Expected getMergeData to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.getMergeData(UserInfo.getUserId(), null);
				throw new AssertException('Expected getMergeData to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeData_invalid_query() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.getMergeData(UserInfo.getUserId(), new Gen.Query(null, null, null, null));
				throw new AssertException('Expected getMergeData to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidGenQuery, ex.getMessage());
			}
			try {
				GenService.getMergeData(UserInfo.getUserId(), new Gen.Query('Lead', null, new List<String>(), null));
				throw new AssertException('Expected getMergeData to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidGenQuery, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getMergeData_success() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Schema.Account a = TestUtils.createAccount();
			Opportunity o = TestUtils.createOpportunity(a.Id);
			Contact c1 = TestUtils.createContact(a.Id);
			Contact c2 = TestUtils.createContact(a.Id);
			OpportunityContactRole ocr1 = TestUtils.createOpportunityContactRole(o.Id, c1.Id);
			OpportunityContactRole ocr2 = TestUtils.createOpportunityContactRole(o.Id, c2.Id);
			Gen.Query q = new Gen.Query('Opportunity', null, new List<String> { 'Name' }, new List<Gen.Query> {
				new Gen.Query('OpportunityContactRole', 'OpportunityContactRoles', new List<String> {
					'Contact.Name', 'Contact.Email', 'Role'
				}, null)
			});

			Test.startTest();
			SObject result = GenService.getMergeData(o.Id, q);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(o.Id, result.Id);
			System.assertEquals(o.Name, (String)result.get('Name'));
			List<OpportunityContactRole> ocrs = (List<OpportunityContactRole>)result.getSObjects('OpportunityContactRoles');
			System.assertEquals(2, Collection.size(ocrs));
			Boolean foundOCR1 = false, foundOCR2 = false;
			for (OpportunityContactRole ocr : ocrs) {
				System.assertNotEquals(null, ocr);
				System.assertNotEquals(null, ocr.Contact);
				if (ocr.Id == ocr1.Id) {
					System.assertEquals(ocr1.Role, ocr.Role);
					System.assertEquals(c1.Id, ocr.Contact.Id);
					System.assertEquals(c1.Name, ocr.Contact.Name);
					System.assertEquals(c1.Email, ocr.Contact.Email);
					foundOCR1 = true;
				} else if (ocr.Id == ocr2.Id) {
					System.assertEquals(ocr2.Role, ocr.Role);
					System.assertEquals(c2.Id, ocr.Contact.Id);
					System.assertEquals(c2.Name, ocr.Contact.Name);
					System.assertEquals(c2.Email, ocr.Contact.Email);
					foundOCR2 = true;
				} else {
					throw new AssertException('Unexpected OpportunityContactRole: ' + ocr.Id);
				}
			}
			System.assert(foundOCR1);
			System.assert(foundOCR2);
		}
	}

	@IsTest
	static void test_getOutputFileName_name() {
		System.assertEquals(null, GenService.getOutputFileName(null, null, null));
		Gen.File f = new Gen.File(null, 'a', 'b', 3, 'docx', 'a', 'name', null);
		System.assertEquals('a', GenService.getOutputFileName(f, null, null));
		System.assertEquals('a_' + UserInfo.getName(), GenService.getOutputFileName(f,
			new Entity(UserInfo.getUserId(), UserInfo.getName(), null), null));
	}

	@IsTest
	static void test_getOutputFileName_date() {
		System.assertEquals(null, GenService.getOutputFileName(null, null, null));
		Gen.File f = new Gen.File(null, 'a', 'b', 3, 'docx', 'a', 'date', null);
		Datetime dt = Datetime.now();
		System.assertEquals('a_' + dt.format('YYYY-MM-dd'), GenService.getOutputFileName(f, null, dt));
	}

	@IsTest
	static void test_getOutputFileName_name_date() {
		System.assertEquals(null, GenService.getOutputFileName(null, null, null));
		Gen.File f = new Gen.File(null, 'a', 'b', 3, 'docx', 'a', 'name_date', null);
		Datetime dt = Datetime.now();
		System.assertEquals('a_' + dt.format('YYYY-MM-dd'), GenService.getOutputFileName(f, null, dt));
		System.assertEquals('a_' + UserInfo.getName() + '_' + dt.format('YYYY-MM-dd'), GenService.getOutputFileName(f,
			new Entity(UserInfo.getUserId(), UserInfo.getName(), null), dt));
	}

	@IsTest
	static void test_queueDocumentGeneration_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenService.queueDocumentGeneration(null, null, null, null, null);
				throw new AssertException('Expected queueDocumentGeneration to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_undefined_arguments() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.queueDocumentGeneration(null, UserInfo.getUserId(), '<xml/>', false, new List<Id> { UserInfo.getUserId() });
				throw new AssertException('Expected queueDocumentGeneration to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.queueDocumentGeneration(UserInfo.getUserId(), null, '<xml/>', false, new List<Id> { UserInfo.getUserId() });
				throw new AssertException('Expected queueDocumentGeneration to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.queueDocumentGeneration(UserInfo.getUserId(), UserInfo.getUserId(), '  ', false, new List<Id> { UserInfo.getUserId() });
				throw new AssertException('Expected queueDocumentGeneration to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.queueDocumentGeneration(UserInfo.getUserId(), UserInfo.getUserId(), '<xml/>', false, new List<Id>());
				throw new AssertException('Expected queueDocumentGeneration to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	private class PartialSuccessMock implements HttpCalloutMock {

		private Integer invocations = 0;
		private final Integer failOnInvocation;
		private final GenAPIMock successMock;
		private final GenAPIMock failureMock;

		public PartialSuccessMock(final Integer failOnInvocation) {
			this.failOnInvocation = failOnInvocation;
			this.successMock = new GenAPIMock(true);
			this.failureMock = new GenAPIMock(false);
		}

		public HttpResponse respond(final HttpRequest request) {
			return ++this.invocations == this.failOnInvocation
				? this.failureMock.getResponse(request)
				: this.successMock.getResponse(request);
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_success_partial() {
		Test.setMock(HttpCalloutMock.class, new PartialSuccessMock(1));
		System.runAs(UserMock.createDocuSignUser()) {
			Lead l = TestUtils.createLead();
			GenTemplate__c gt = TestUtils.createGenTemplate(Lead.getSObjectType());
			ContentVersion cv1 = TestUtils.createGenFile(gt.Id);
			ContentVersion cv2 = TestUtils.createGenFile(gt.Id);

			Test.startTest();
			List<Gen.Job> result = GenService.queueDocumentGeneration(gt.Id, l.Id, '<xml/>', true, new List<Id> {
				cv1.ContentDocumentId, cv2.ContentDocumentId
			});
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(null, result[0].id);
			System.assertEquals(cv1.Id, result[0].fileId);
			System.assertEquals(Label.Failure, result[0].status);
			System.assertNotEquals(null, result[0].message);
			System.assert(result[0].message.contains('Test user message'));
			System.assert(!result[0].success);
			System.assertNotEquals(null, result[1]);
			System.assert(UUID.isNotEmpty(result[1].id));
			System.assertEquals(cv2.Id, result[1].fileId);
			System.assertEquals(Label.Queued, result[1].status);
			System.assertEquals(null, result[1].message);
			System.assert(!result[1].success);
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_preview() {
		GenAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			Lead l = TestUtils.createLead();
			GenTemplate__c gt = TestUtils.createGenTemplate(Lead.getSObjectType());
			ContentVersion cv1 = TestUtils.createGenFile(gt.Id);
			ContentVersion cv2 = TestUtils.createGenFile(gt.Id);

			Test.startTest();
			List<Gen.Job> result = GenService.queueDocumentGeneration(gt.Id, l.Id, '<xml/>', true, new List<Id> {
				cv1.ContentDocumentId, cv2.ContentDocumentId
			});
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assert(UUID.isNotEmpty(result[0].id));
			System.assertEquals(cv1.Id, result[0].fileId);
			System.assertEquals(Label.Queued, result[0].status);
			System.assertEquals(null, result[0].message);
			System.assert(!result[0].success);
			System.assertNotEquals(null, result[1]);
			System.assert(UUID.isNotEmpty(result[1].id));
			System.assertEquals(cv2.Id, result[1].fileId);
			System.assertEquals(Label.Queued, result[1].status);
			System.assertEquals(null, result[1].message);
			System.assert(!result[1].success);
		}
	}

	@IsTest
	static void test_queueDocumentGeneration_source() {
		GenAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			Lead l = TestUtils.createLead();
			GenTemplate__c gt = TestUtils.createGenTemplate(Lead.getSObjectType());
			ContentVersion cv1 = TestUtils.createGenFile(gt.Id);
			ContentVersion cv2 = TestUtils.createGenFile(gt.Id);

			Test.startTest();
			List<Gen.Job> result = GenService.queueDocumentGeneration(gt.Id, l.Id, '<xml/>', false, new List<Id> {
				cv1.ContentDocumentId, cv2.ContentDocumentId
			});
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assert(UUID.isNotEmpty(result[0].id));
			System.assertEquals(cv1.Id, result[0].fileId);
			System.assertEquals(Label.Queued, result[0].status);
			System.assertEquals(null, result[0].message);
			System.assert(!result[0].success);
			System.assertNotEquals(null, result[1]);
			System.assert(UUID.isNotEmpty(result[1].id));
			System.assertEquals(cv2.Id, result[1].fileId);
			System.assertEquals(Label.Queued, result[1].status);
			System.assertEquals(null, result[1].message);
			System.assert(!result[1].success);
		}
	}

	@IsTest
	static void test_getJobStatus_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				GenService.getJobStatus(null);
				throw new AssertException('Expected getJobStatus to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getJobStatus_invalid_argument() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				GenService.getJobStatus(null);
				throw new AssertException('Expected getJobStatus to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				GenService.getJobStatus(new List<UUID>());
				throw new AssertException('Expected getJobStatus to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getJobStatus_success() {
		GenAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Lead.getSObjectType());
			ContentVersion cv = TestUtils.createGenFile(gt.Id);
			UUID jobId1 = UUID.randomUUID();

			Test.startTest();
			List<Gen.Job> result = GenService.getJobStatus(new List<UUID> { jobId1 });
			Test.stopTest();

			System.assertEquals(1, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(jobId1, result[0].id);
			System.assertEquals(cv.Id, result[0].fileId);
			System.assertEquals('Success', result[0].status);
			System.assert(result[0].success);
			System.assertNotEquals(null, result[0].file);
			System.assertEquals(cv.Id, result[0].file.id);
			System.assertEquals(cv.Title, result[0].file.title);
			System.assertEquals(cv.FileExtension, result[0].file.extension);
			System.assertEquals(cv.ContentSize, result[0].file.size);
			System.assertEquals(cv.GeneratedFileFormat__c, result[0].file.generatedFormat);
			System.assertEquals(cv.GeneratedFileName__c, result[0].file.generatedName);
			System.assertEquals(cv.GeneratedFileSuffix__c, result[0].file.generatedSuffix);
		}
	}

	@IsTest
	static void test_getJobStatus_success_partial() {
		Test.setMock(HttpCalloutMock.class, new PartialSuccessMock(1));
		System.runAs(UserMock.createDocuSignUser()) {
			GenTemplate__c gt = TestUtils.createGenTemplate(Lead.getSObjectType());
			ContentVersion cv = TestUtils.createGenFile(gt.Id);
			UUID jobId1 = UUID.randomUUID(), jobId2 = UUID.randomUUID();

			Test.startTest();
			List<Gen.Job> result = GenService.getJobStatus(new List<UUID> { jobId1, jobId2 });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(jobId1, result[0].id);
			System.assertEquals(null, result[0].fileId);
			System.assertEquals(Label.Unknown, result[0].status);
			System.assert(!result[0].success);
			System.assert(String.isNotBlank(result[0].message));

			System.assertNotEquals(null, result[1]);
			System.assertEquals(jobId2, result[1].id);
			System.assertEquals(cv.Id, result[1].fileId);
			System.assertEquals('Success', result[1].status);
			System.assert(result[1].success);
			System.assertNotEquals(null, result[1].file);
			System.assertEquals(cv.Id, result[1].file.id);
			System.assertEquals(cv.Title, result[1].file.title);
			System.assertEquals(cv.FileExtension, result[1].file.extension);
			System.assertEquals(cv.ContentSize, result[1].file.size);
			System.assertEquals(cv.GeneratedFileFormat__c, result[1].file.generatedFormat);
			System.assertEquals(cv.GeneratedFileName__c, result[1].file.generatedName);
			System.assertEquals(cv.GeneratedFileSuffix__c, result[1].file.generatedSuffix);
		}
	}
}
