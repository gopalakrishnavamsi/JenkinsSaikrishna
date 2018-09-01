@IsTest
private class BulkSendServiceTest {

	private static BulkList__c createList(final Id sourceId) {
		BulkList__c bl = new BulkList__c(
			DocuSignId__c = UUID.randomUUID().toString(),
			Name = UUID.randomUUID().toString(),
			SourceId__c = sourceId);
		insert bl;
		return bl;
	}

	private static BulkStatus__c createStatus(final Id sourceId) {
		BulkStatus__c bs = new BulkStatus__c(
			DocuSignId__c = UUID.randomUUID().toString(),
			SourceId__c = sourceId,
			BatchSize__c = TestUtils.randomInteger(100),
			QueuedEnvelopes__c = TestUtils.randomInteger(100),
			SentEnvelopes__c = TestUtils.randomInteger(100),
			FailedEnvelopes__c = TestUtils.randomInteger(100),
			Submitted__c = Datetime.now().addDays(-(TestUtils.randomInteger(10))),
			LastStatusUpdate__c = Datetime.now().addDays(-(TestUtils.randomInteger(10))));
		insert bs;
		return bs;
	}

	@IsTest
	static void test_Database_convert() {
		System.runAs(UserMock.createUser()) {
			BulkList__c bl1 = createList(TestUtils.createLead().Id);
			BulkList__c bl2 = createList(TestUtils.createLead().Id);
			BulkStatus__c bs1 = createStatus(TestUtils.createLead().Id);
			BulkStatus__c bs2 = createStatus(TestUtils.createLead().Id);

			Test.startTest();
			List<BulkList__c> result1 = BulkSendService.DB.convert(BulkSendService.DB.convert(new List<BulkList__c> { bl1, bl2 }));
			List<BulkStatus__c> result2 = BulkSendService.DB.convert(BulkSendService.DB.convert(new List<BulkStatus__c> { bs1, bs2 }));
			Test.stopTest();

			System.assert(Collection.size(result1) == 2);
			BulkList__c blr1 = result1[0];
			System.assertNotEquals(null, blr1);
			System.assertEquals(bl1.Id, blr1.Id);
			System.assertEquals(bl1.DocuSignId__c, blr1.DocuSignId__c);
			System.assertEquals(bl1.Name, blr1.Name);
			System.assertEquals(bl1.SourceId__c, blr1.SourceId__c);
			BulkList__c blr2 = result1[1];
			System.assertNotEquals(null, blr2);
			System.assertEquals(bl2.Id, blr2.Id);
			System.assertEquals(bl2.DocuSignId__c, blr2.DocuSignId__c);
			System.assertEquals(bl2.Name, blr2.Name);
			System.assertEquals(bl2.SourceId__c, blr2.SourceId__c);

			System.assert(Collection.size(result2) == 2);
			BulkStatus__c bsr1 = result2[0];
			System.assertNotEquals(null, bsr1);
			System.assertEquals(bs1.Id, bsr1.Id);
			System.assertEquals(bs1.DocuSignId__c, bsr1.DocuSignId__c);
			System.assertEquals(bs1.SourceId__c, bsr1.SourceId__c);
			System.assertEquals(bs1.BatchSize__c, bsr1.BatchSize__c);
			System.assertEquals(bs1.QueuedEnvelopes__c, bsr1.QueuedEnvelopes__c);
			System.assertEquals(bs1.SentEnvelopes__c, bsr1.SentEnvelopes__c);
			System.assertEquals(bs1.FailedEnvelopes__c, bsr1.FailedEnvelopes__c);
			System.assertEquals(bs1.Submitted__c, bsr1.Submitted__c);
			System.assertEquals(bs1.LastStatusUpdate__c, bsr1.LastStatusUpdate__c);
			BulkStatus__c bsr2 = result2[1];
			System.assertNotEquals(null, bsr2);
			System.assertEquals(bs2.Id, bsr2.Id);
			System.assertEquals(bs2.DocuSignId__c, bsr2.DocuSignId__c);
			System.assertEquals(bs2.SourceId__c, bsr2.SourceId__c);
			System.assertEquals(bs2.BatchSize__c, bsr2.BatchSize__c);
			System.assertEquals(bs2.QueuedEnvelopes__c, bsr2.QueuedEnvelopes__c);
			System.assertEquals(bs2.SentEnvelopes__c, bsr2.SentEnvelopes__c);
			System.assertEquals(bs2.FailedEnvelopes__c, bsr2.FailedEnvelopes__c);
			System.assertEquals(bs2.Submitted__c, bsr2.Submitted__c);
			System.assertEquals(bs2.LastStatusUpdate__c, bsr2.LastStatusUpdate__c);
		}
	}

	@IsTest
	static void test_Database_createLists() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			BulkList bl1 = BulkList.newList(
				UUID.randomUUID().toString(),
				new List<Envelope> {
					Envelope.newBulkCopy(Recipient.newBulkRecipient(
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString() + '@unit.test',
						null))
				},
				new Entity(UserInfo.getUserId()));
			BulkList bl2 = BulkList.newList(
				UUID.randomUUID().toString(),
				new List<Envelope> {
					Envelope.newBulkCopy(Recipient.newBulkRecipient(
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString() + '@unit.test',
						null))
				},
				new Entity(UserInfo.getUserId()));

			Test.startTest();
			List<BulkList> result = BulkSendService.DB.createLists(new List<BulkList> { bl1, bl2 });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertNotEquals(null, result[0].id);
			System.assertEquals(bl1.docuSignId, result[0].docuSignId);
			System.assertEquals(bl1.name, result[0].name);
			System.assertEquals(bl1.source, result[0].source);
			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].id);
			System.assertEquals(bl2.docuSignId, result[1].docuSignId);
			System.assertEquals(bl2.name, result[1].name);
			System.assertEquals(bl2.source, result[1].source);
		}
	}

	@IsTest
	static void test_Database_queryLists_by_id() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			BulkList bl1 = BulkSendService.DB.convert(createList(TestUtils.createAccount().Id));
			BulkList bl2 = BulkSendService.DB.convert(createList(TestUtils.createAccount().Id));

			Test.startTest();
			List<BulkList> result = BulkSendService.DB.queryLists(new Set<Id> { bl1.id, bl2.id });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(bl1.id, result[0].id);
			System.assertEquals(bl1.docuSignId, result[0].docuSignId);
			System.assertEquals(bl1.name, result[0].name);
			System.assertEquals(bl1.source, result[0].source);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(bl2.id, result[1].id);
			System.assertEquals(bl2.docuSignId, result[1].docuSignId);
			System.assertEquals(bl2.name, result[1].name);
			System.assertEquals(bl2.source, result[1].source);
		}
	}

	@IsTest
	static void test_Database_queryLists_by_name() {
		System.runAs(UserMock.createDocuSignUser()) {
			BulkList__c bl1 = new BulkList__c(
				DocuSignId__c = UUID.randomUUID().toString(),
				Name = 'XX ' + UUID.randomUUID().toString(),
				SourceId__c = UserInfo.getUserId());
			BulkList__c bl2 = new BulkList__c(
				DocuSignId__c = UUID.randomUUID().toString(),
				Name = 'XY ' + UUID.randomUUID().toString(),
				SourceId__c = UserInfo.getOrganizationId());
			BulkList__c bl3 = new BulkList__c(
				DocuSignId__c = UUID.randomUUID().toString(),
				Name = 'YY ' + UUID.randomUUID().toString(),
				SourceId__c = UserInfo.getProfileId());
			insert new List<BulkList__c> { bl1, bl2, bl3 };

			Test.startTest();
			List<BulkList> result1 = BulkSendService.DB.queryLists(null, 100);
			List<BulkList> result2 = BulkSendService.DB.queryLists('X', 1);
			List<BulkList> result3 = BulkSendService.DB.queryLists('X', null);
			Test.stopTest();

			System.assertEquals(3, Collection.size(result1));
			System.assertNotEquals(null, result1[0]);
			System.assertEquals(bl1.Id, result1[0].id);
			System.assertEquals(bl1.DocuSignId__c, String.valueOf(result1[0].docuSignId));
			System.assertEquals(bl1.Name, result1[0].name);
			System.assertNotEquals(null, result1[0].source);
			System.assertEquals(bl1.SourceId__c, result1[0].source.id);
			System.assertNotEquals(null, result1[1]);
			System.assertEquals(bl2.Id, result1[1].id);
			System.assertEquals(bl2.DocuSignId__c, String.valueOf(result1[1].docuSignId));
			System.assertEquals(bl2.Name, result1[1].name);
			System.assertNotEquals(null, result1[1].source);
			System.assertEquals(bl2.SourceId__c, result1[1].source.id);
			System.assertNotEquals(null, result1[2]);
			System.assertEquals(bl3.Id, result1[2].id);
			System.assertEquals(bl3.DocuSignId__c, String.valueOf(result1[2].docuSignId));
			System.assertEquals(bl3.Name, result1[2].name);
			System.assertNotEquals(null, result1[2].source);
			System.assertEquals(bl3.SourceId__c, result1[2].source.id);

			System.assertEquals(1, Collection.size(result2));
			System.assertNotEquals(null, result2[0]);
			System.assertEquals(bl1.Id, result2[0].id);
			System.assertEquals(bl1.DocuSignId__c, String.valueOf(result2[0].docuSignId));
			System.assertEquals(bl1.Name, result2[0].name);
			System.assertNotEquals(null, result2[0].source);
			System.assertEquals(bl1.SourceId__c, result2[0].source.id);

			System.assertEquals(2, Collection.size(result3));
			System.assertNotEquals(null, result3[0]);
			System.assertEquals(bl1.Id, result3[0].id);
			System.assertEquals(bl1.DocuSignId__c, String.valueOf(result3[0].docuSignId));
			System.assertEquals(bl1.Name, result3[0].name);
			System.assertNotEquals(null, result3[0].source);
			System.assertEquals(bl1.SourceId__c, result3[0].source.id);
			System.assertNotEquals(null, result3[1]);
			System.assertEquals(bl2.Id, result3[1].id);
			System.assertEquals(bl2.DocuSignId__c, String.valueOf(result3[1].docuSignId));
			System.assertEquals(bl2.Name, result3[1].name);
			System.assertNotEquals(null, result3[1].source);
			System.assertEquals(bl2.SourceId__c, result3[1].source.id);
		}
	}

	@IsTest
	static void test_Database_updateLists() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			BulkList bl1 = BulkSendService.DB.convert(createList(TestUtils.createLead().Id));
			BulkList bl2 = BulkSendService.DB.convert(createList(TestUtils.createLead().Id));

			Test.startTest();
			List<BulkList> result = BulkSendService.DB.updateLists(new List<BulkList> { bl1, bl2 });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(bl1.id, result[0].id);
			System.assertEquals(bl1.docuSignId, result[0].docuSignId);
			System.assertEquals(bl1.name, result[0].name);
			System.assertEquals(bl1.source, result[0].source);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(bl2.id, result[1].id);
			System.assertEquals(bl2.docuSignId, result[1].docuSignId);
			System.assertEquals(bl2.name, result[1].name);
			System.assertEquals(bl2.source, result[1].source);
		}
	}

	@IsTest
	static void test_Database_deleteLists() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Set<Id> ids = new Set<Id> {
				createList(null).Id,
				createList(null).Id
			};

			Test.startTest();
			Boolean result = BulkSendService.DB.deleteLists(ids);
			Test.stopTest();

			System.assert(result);
			System.assert(Collection.isEmpty([SELECT Id FROM BulkList__c WHERE Id IN :ids]));
		}
	}

	@IsTest
	static void test_Database_createStatus() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			BulkList.Status bs1 = new BulkList.Status(
				null,
				UUID.randomUUID(),
				new Entity(TestUtils.createLead().Id),
				TestUtils.randomInteger(100),
				TestUtils.randomInteger(100),
				TestUtils.randomInteger(100),
				TestUtils.randomInteger(100),
				null,
				Datetime.now().addDays(-(TestUtils.randomInteger(10))),
				Datetime.now().addDays(-(TestUtils.randomInteger(10))));
			BulkList.Status bs2 = new BulkList.Status(
				null,
				UUID.randomUUID(),
				new Entity(TestUtils.createLead().Id),
				TestUtils.randomInteger(100),
				TestUtils.randomInteger(100),
				TestUtils.randomInteger(100),
				TestUtils.randomInteger(100),
				null,
				Datetime.now().addDays(-(TestUtils.randomInteger(10))),
				Datetime.now().addDays(-(TestUtils.randomInteger(10))));

			Test.startTest();
			List<BulkList.Status> result = BulkSendService.DB.createStatus(new List<BulkList.Status> { bs1, bs2 });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertNotEquals(null, result[0].id);
			System.assertEquals(bs1.docuSignId, result[0].docuSignId);
			System.assertEquals(bs1.source, result[0].source);
			System.assertEquals(bs1.batchSize, result[0].batchSize);
			System.assertEquals(bs1.queuedEnvelopes, result[0].queuedEnvelopes);
			System.assertEquals(bs1.sentEnvelopes, result[0].sentEnvelopes);
			System.assertEquals(bs1.failedEnvelopes, result[0].failedEnvelopes);
			System.assertEquals(bs1.submitted, result[0].submitted);
			System.assertEquals(bs1.lastStatusUpdate, result[0].lastStatusUpdate);
			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].id);
			System.assertEquals(bs2.docuSignId, result[1].docuSignId);
			System.assertEquals(bs2.source, result[1].source);
			System.assertEquals(bs2.batchSize, result[1].batchSize);
			System.assertEquals(bs2.queuedEnvelopes, result[1].queuedEnvelopes);
			System.assertEquals(bs2.sentEnvelopes, result[1].sentEnvelopes);
			System.assertEquals(bs2.failedEnvelopes, result[1].failedEnvelopes);
			System.assertEquals(bs2.submitted, result[1].submitted);
			System.assertEquals(bs2.lastStatusUpdate, result[1].lastStatusUpdate);
		}
	}

	@IsTest
	static void test_Database_queryStatus() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			BulkList.Status bs1 = BulkSendService.DB.convert(createStatus(TestUtils.createLead().Id));
			BulkList.Status bs2 = BulkSendService.DB.convert(createStatus(TestUtils.createLead().Id));

			Test.startTest();
			List<BulkList.Status> result = BulkSendService.DB.queryStatus(new Set<Id> { bs1.Id, bs2.Id });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(bs1.id, result[0].id);
			System.assertEquals(bs1.docuSignId, result[0].docuSignId);
			System.assertEquals(bs1.source, result[0].source);
			System.assertEquals(bs1.batchSize, result[0].batchSize);
			System.assertEquals(bs1.queuedEnvelopes, result[0].queuedEnvelopes);
			System.assertEquals(bs1.sentEnvelopes, result[0].sentEnvelopes);
			System.assertEquals(bs1.failedEnvelopes, result[0].failedEnvelopes);
			System.assertEquals(bs1.submitted, result[0].submitted);
			System.assertEquals(bs1.lastStatusUpdate, result[0].lastStatusUpdate);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(bs2.id, result[1].id);
			System.assertEquals(bs2.docuSignId, result[1].docuSignId);
			System.assertEquals(bs2.source, result[1].source);
			System.assertEquals(bs2.batchSize, result[1].batchSize);
			System.assertEquals(bs2.queuedEnvelopes, result[1].queuedEnvelopes);
			System.assertEquals(bs2.sentEnvelopes, result[1].sentEnvelopes);
			System.assertEquals(bs2.failedEnvelopes, result[1].failedEnvelopes);
			System.assertEquals(bs2.submitted, result[1].submitted);
			System.assertEquals(bs2.lastStatusUpdate, result[1].lastStatusUpdate);
		}
	}

	@IsTest
	static void test_Database_updateStatus() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			BulkList.Status bs1 = new BulkList.Status(
				createStatus(null).Id,
				UUID.randomUUID(),
				new Entity(TestUtils.createLead().Id),
				TestUtils.randomInteger(100),
				TestUtils.randomInteger(100),
				TestUtils.randomInteger(100),
				TestUtils.randomInteger(100),
				null,
				Datetime.now().addDays(-(TestUtils.randomInteger(10))),
				Datetime.now().addDays(-(TestUtils.randomInteger(10))));
			BulkList.Status bs2 = new BulkList.Status(
				createStatus(null).Id,
				UUID.randomUUID(),
				new Entity(TestUtils.createLead().Id),
				TestUtils.randomInteger(100),
				TestUtils.randomInteger(100),
				TestUtils.randomInteger(100),
				TestUtils.randomInteger(100),
				null,
				Datetime.now().addDays(-(TestUtils.randomInteger(10))),
				Datetime.now().addDays(-(TestUtils.randomInteger(10))));

			Test.startTest();
			List<BulkList.Status> result = BulkSendService.DB.updateStatus(new List<BulkList.Status> { bs1, bs2 });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(bs1.id, result[0].id);
			System.assertEquals(bs1.docuSignId, result[0].docuSignId);
			System.assertEquals(bs1.source, result[0].source);
			System.assertEquals(bs1.batchSize, result[0].batchSize);
			System.assertEquals(bs1.queuedEnvelopes, result[0].queuedEnvelopes);
			System.assertEquals(bs1.sentEnvelopes, result[0].sentEnvelopes);
			System.assertEquals(bs1.failedEnvelopes, result[0].failedEnvelopes);
			System.assertEquals(bs1.submitted, result[0].submitted);
			System.assertEquals(bs1.lastStatusUpdate, result[0].lastStatusUpdate);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(bs2.id, result[1].id);
			System.assertEquals(bs2.docuSignId, result[1].docuSignId);
			System.assertEquals(bs2.source, result[1].source);
			System.assertEquals(bs2.batchSize, result[1].batchSize);
			System.assertEquals(bs2.queuedEnvelopes, result[1].queuedEnvelopes);
			System.assertEquals(bs2.sentEnvelopes, result[1].sentEnvelopes);
			System.assertEquals(bs2.failedEnvelopes, result[1].failedEnvelopes);
			System.assertEquals(bs2.submitted, result[1].submitted);
			System.assertEquals(bs2.lastStatusUpdate, result[1].lastStatusUpdate);
		}
	}

	@IsTest
	static void test_createLists_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				BulkSendService.createLists(new List<BulkList> {
					BulkList.newList(
						UUID.randomUUID().toString(),
						new List<Envelope> {
							Envelope.newBulkCopy(Recipient.newBulkRecipient(
								UUID.randomUUID().toString(),
								UUID.randomUUID().toString() + '@unit.test',
								null))
						},
						new Entity(UserInfo.getUserId()))
				});
				throw new AssertException('Expected createLists to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createLists_empty() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				BulkSendService.createLists(new List<BulkList>());
				throw new AssertException('Expected createLists to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedBulkList, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createLists_api_error() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				BulkSendService.createLists(new List<BulkList> {
					BulkList.newList(
						UUID.randomUUID().toString(),
						new List<Envelope> {
							Envelope.newBulkCopy(Recipient.newBulkRecipient(
								UUID.randomUUID().toString(),
								UUID.randomUUID().toString() + '@unit.test',
								null))
						},
						new Entity(UserInfo.getUserId()))
				});
				throw new AssertException('Expected createLists to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createLists_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			BulkList bl1 = BulkList.newList(
				UUID.randomUUID().toString(),
				new List<Envelope> {
					Envelope.newBulkCopy(Recipient.newBulkRecipient(
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString() + '@unit.test',
						null))
				},
				new Entity(UserInfo.getUserId()));
			BulkList bl2 = BulkList.newList(
				UUID.randomUUID().toString(),
				new List<Envelope> {
					Envelope.newBulkCopy(Recipient.newBulkRecipient(
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString() + '@unit.test',
						null))
				},
				new Entity(UserInfo.getOrganizationId()));

			Test.startTest();
			List<BulkList> result = BulkSendService.createLists(new List<BulkList> { bl1, bl2 });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertNotEquals(null, result[0].id);
			System.assertNotEquals(null, result[0].docuSignId);
			System.assertNotEquals(null, result[1]);
			System.assertNotEquals(null, result[1].id);
			System.assertNotEquals(null, result[1].docuSignId);
		}
	}

	@IsTest
	static void test_searchLists_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				BulkSendService.searchLists(null, null);
				throw new AssertException('Expected searchLists to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_searchLists_success() {
		System.runAs(UserMock.createDocuSignUser()) {
			BulkList__c bl1 = new BulkList__c(
				DocuSignId__c = UUID.randomUUID().toString(),
				Name = 'XX ' + UUID.randomUUID().toString(),
				SourceId__c = UserInfo.getUserId());
			BulkList__c bl2 = new BulkList__c(
				DocuSignId__c = UUID.randomUUID().toString(),
				Name = 'XY ' + UUID.randomUUID().toString(),
				SourceId__c = UserInfo.getOrganizationId());
			BulkList__c bl3 = new BulkList__c(
				DocuSignId__c = UUID.randomUUID().toString(),
				Name = 'YY ' + UUID.randomUUID().toString(),
				SourceId__c = UserInfo.getProfileId());
			insert new List<BulkList__c> { bl1, bl2, bl3 };

			Test.startTest();
			List<BulkList> result1 = BulkSendService.searchLists(null, 100);
			List<BulkList> result2 = BulkSendService.searchLists('X', 1);
			List<BulkList> result3 = BulkSendService.searchLists('X', null);
			Test.stopTest();

			System.assertEquals(3, Collection.size(result1));
			System.assertEquals(1, Collection.size(result2));
			System.assertEquals(2, Collection.size(result3));
		}
	}

	@IsTest
	static void test_updateLists_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				BulkSendService.updateLists(new List<BulkList> {
					BulkList.newList(
						UUID.randomUUID().toString(),
						new List<Envelope> {
							Envelope.newBulkCopy(Recipient.newBulkRecipient(
								UUID.randomUUID().toString(),
								UUID.randomUUID().toString() + '@unit.test',
								null))
						},
						new Entity(UserInfo.getUserId()))
				});
				throw new AssertException('Expected updateLists to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateLists_empty() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				BulkSendService.updateLists(new List<BulkList>());
				throw new AssertException('Expected updateLists to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedBulkList, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateLists_api_error() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				BulkSendService.updateLists(new List<BulkList> {
					BulkList.newList(
						UUID.randomUUID().toString(),
						new List<Envelope> {
							Envelope.newBulkCopy(Recipient.newBulkRecipient(
								UUID.randomUUID().toString(),
								UUID.randomUUID().toString() + '@unit.test',
								null))
						},
						new Entity(UserInfo.getUserId()))
				});
				throw new AssertException('Expected updateLists to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateLists_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			BulkList bl1 = new BulkList(
				createList(null).Id,
				UUID.randomUUID(),
				'list 1',
				null, // ignored for now
				new Entity(UserInfo.getUserId()));
			BulkList bl2 = new BulkList(
				createList(null).Id,
				UUID.randomUUID(),
				'list 2',
				null, // ignored for now
				new Entity(UserInfo.getOrganizationId()));

			Test.startTest();
			List<BulkList> result = BulkSendService.updateLists(new List<BulkList> { bl1, bl2 });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertNotEquals(null, result[0]);
			System.assertEquals(bl1.id, result[0].id);
			System.assertEquals(bl1.docuSignId, result[0].docuSignId);
			System.assertEquals(bl1.source, result[0].source);
			System.assertNotEquals(null, result[1]);
			System.assertEquals(bl2.id, result[1].id);
			System.assertEquals(bl2.docuSignId, result[1].docuSignId);
			System.assertEquals(bl2.source, result[1].source);
		}
	}

	@IsTest
	static void test_deleteLists_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				BulkSendService.deleteLists(new Set<Id> { UserInfo.getUserId() });
				throw new AssertException('Expected deleteLists to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteLists_empty() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				BulkSendService.deleteLists(new Set<Id>());
				throw new AssertException('Expected deleteLists to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedId, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteLists_api_error() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			BulkList__c bl1 = createList(null);
			BulkList__c bl2 = createList(null);

			Test.startTest();
			try {
				BulkSendService.deleteLists(new Set<Id> { bl1.Id, bl2.Id });
				throw new AssertException('Expected deleteLists to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_deleteLists_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Set<Id> ids = new Set<Id> { createList(null).Id, createList(null).Id };

			Test.startTest();
			Boolean result1 = BulkSendService.deleteLists(ids);
			Boolean result2 = BulkSendService.deleteLists(ids);
			Test.stopTest();

			System.assert(result1);
			System.assert(!result2);
			System.assert(Collection.isEmpty([SELECT Id FROM BulkList__c WHERE Id IN :ids]));
		}
	}

	@IsTest
	static void test_getDraftEnvelope_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				BulkSendService.getDraftEnvelope(null, null);
				throw new AssertException('Expected getDraftEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getDraftEnvelope_no_documents() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			try {
				BulkSendService.getDraftEnvelope(null, null);
				throw new AssertException('Expected getDraftEnvelope to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.AtLeastOneDocumentIsRequired, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getDraftEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Document d = DocumentService.convert(TestUtils.createContentVersion());

			Test.startTest();
			Envelope result = BulkSendService.getDraftEnvelope(new List<Document> { d }, null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1, Collection.size(result.documents));
			System.assertEquals(1, Collection.size(result.recipients));
		}
	}

	@IsTest
	static void test_sendEnvelope_unauthorized() {
		Envelope e;
		System.runAs(UserMock.createDocuSignUser(false)) {
			e = EnvelopeService.DB.convert(TestUtils.createEnvelope());
		}

		System.runAs(UserMock.createDocuSignUser(false)) {
			BulkList bl = BulkSendService.DB.convert(createList(null));

			Test.startTest();
			try {
				BulkSendService.sendEnvelope(bl.id, e);
				throw new AssertException('Expected sendEnvelope to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.NotEnvelopeOwner, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendEnvelope_invalid_argument() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			BulkList bl = BulkSendService.DB.convert(createList(null));
			Envelope e = EnvelopeService.getEmptyEnvelope(null);

			Test.startTest();
			try {
				BulkSendService.sendEnvelope(null, e);
				throw new AssertException('Expected sendEnvelope to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedBulkList, ex.getMessage());
			}
			try {
				BulkSendService.sendEnvelope(bl.id, null);
				throw new AssertException('Expected sendEnvelope to fail');
			} catch (ValidationException ex) {
				System.assert(ex.getMessage().startsWith(Label.InvalidEnvelope));
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendEnvelope_invalid_envelope() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			BulkList bl = BulkSendService.DB.convert(createList(null));
			Envelope e = EnvelopeService.DB.convert(TestUtils.createEnvelope());

			Test.startTest();
			try {
				BulkSendService.sendEnvelope(bl.id, e);
				throw new AssertException('Expected sendEnvelope to fail');
			} catch (ValidationException ex) {
				System.assert(ex.getMessage().startsWith(Label.InvalidEnvelope));
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendEnvelope_api_error() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			BulkList bl = BulkSendService.DB.convert(createList(null));
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope e = EnvelopeService.DB.convert(e1)
				.withDocuments(DocumentService.convert(new List<Document__c> { TestUtils.createEnvelopeDocument(e1.Id) }))
				.withRecipients(RecipientService.convert(new List<Recipient__c> { TestUtils.createEnvelopeRecipient(e1.Id) }));

			Test.startTest();
			try {
				BulkSendService.sendEnvelope(bl.id, e);
				throw new AssertException('Expected sendEnvelope to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_sendEnvelope_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			BulkList bl = BulkSendService.DB.convert(createList(null));
			Envelope__c e1 = TestUtils.createEnvelope();
			Envelope e = EnvelopeService.DB.convert(e1)
				.withDocuments(new List<Document> {
					DocumentService.convert(TestUtils.createContentVersion())
				})
				.withRecipients(new List<Recipient> {
					Recipient.newBulkRecipientPlaceholder()
				});

			Test.startTest();
			BulkList.Result result = BulkSendService.sendEnvelope(bl.id, e);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.bulkStatusId);
			System.assertNotEquals(null, result.batchId);
			System.assertEquals(1, Collection.size([SELECT Id FROM BulkStatus__c WHERE Id = :result.bulkStatusId]));

		}
	}

	@IsTest
	static void test_sendEnvelope_with_create() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			BulkList bl = BulkSendService.DB.convert(createList(null));
			Envelope e = BulkSendService.getDraftEnvelope(
				new List<Document> {
					DocumentService.convert(TestUtils.createContentVersion())
				},
				null);

			Test.startTest();
			BulkList.Result result = BulkSendService.sendEnvelope(bl.id, e);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.bulkStatusId);
			System.assertNotEquals(null, result.batchId);
			System.assertEquals(1, Collection.size([SELECT Id FROM BulkStatus__c WHERE Id = :result.bulkStatusId]));

		}
	}

	@IsTest
	static void test_getStatus_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				BulkSendService.getStatus(new Set<Id> { UserInfo.getUserId() });
				throw new AssertException('Expected getStatus to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignUser, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getStatus_invalid() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				BulkSendService.getStatus(new Set<Id>());
				throw new AssertException('Expected getStatus to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedId, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getStatus_api_error() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		System.runAs(UserMock.createDocuSignUser()) {
			BulkStatus__c bs = createStatus(null);
			bs.LastStatusUpdate__c = Datetime.now().addDays(-1);
			update bs;

			Test.startTest();
			try {
				BulkSendService.getStatus(new Set<Id> { bs.Id });
				throw new AssertException('Expected getStatus to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.BAD_REQUEST, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getStatus_success_cached() {
		System.runAs(UserMock.createDocuSignUser()) {
			BulkStatus__c bs1 = createStatus(null);
			bs1.LastStatusUpdate__c = Datetime.now();
			BulkStatus__c bs2 = createStatus(null);
			bs2.LastStatusUpdate__c = Datetime.now();
			update new List<BulkStatus__c> { bs1, bs2 };

			Test.startTest();
			List<BulkList.Status> result = BulkSendService.getStatus(new Set<Id> { bs1.Id, bs2.Id });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
		}
	}

	@IsTest
	static void test_getStatus_success_not_cached() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			BulkStatus__c bs1 = createStatus(null);
			bs1.LastStatusUpdate__c = Datetime.now().addDays(-1);
			BulkStatus__c bs2 = createStatus(null);
			bs2.LastStatusUpdate__c = Datetime.now().addDays(-1);
			update new List<BulkStatus__c> { bs1 };

			Test.startTest();
			List<BulkList.Status> result = BulkSendService.getStatus(new Set<Id> { bs1.Id, bs2.Id });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
		}
	}
}
