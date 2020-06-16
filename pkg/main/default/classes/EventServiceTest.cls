@IsTest
private class EventServiceTest {

	static EventService.Event createEvent(
		final UUID envelopeId,
		final String status,
		final Id sourceId) {

		EventService.Event result = new EventService.Event();
		result.envelopeId = String.valueOf(envelopeId);
		result.status = status;
		if (String.isNotBlank(sourceId)) {
			CustomField cf = CustomField.forEnvelopeSource(sourceId);
			EventService.EventCustomField ecf = new EventService.EventCustomField();
			ecf.name = cf.name;
			ecf.value = cf.value;
			result.customFields = new List<EventService.EventCustomField> { ecf };
		}
		return result;
	}

	static EventService.Event createEvent(
		final Envelope__c envelope,
		final String envelopeStatus,
		final Map<Recipient__c, String> recipientStatus) {

		EventService.Event result = new EventService.Event();
		result.envelopeId = envelope.DocuSignId__c;
		result.status = envelopeStatus;
		if (String.isNotBlank(envelope.SourceId__c)) {
			CustomField cf = CustomField.forEnvelopeSource(envelope.SourceId__c);
			EventService.EventCustomField ecf = new EventService.EventCustomField();
			ecf.name = cf.name;
			ecf.value = cf.value;
			result.customFields = new List<EventService.EventCustomField> { ecf };
		}
		if (recipientStatus != null) {
			result.recipientStatuses = new EventService.EventRecipients();
			result.recipientStatuses.recipientStatus = new List<EventService.EventRecipient>();
			for (Recipient__c r : recipientStatus.keySet()) {
				EventService.EventRecipient er = new EventService.EventRecipient();
				er.recipientId = UUID.randomUUID().toString();
				er.status = recipientStatus.get(r);
				er.type = r.Type__c;
				er.email = r.Email__c;
				er.username = r.Name;
				if (String.isNotBlank(r.SourceId__c)) {
					er.customFields = new List<String> { CustomField.forRecipientSource(r.SourceId__c) };
				}
				result.recipientStatuses.recipientStatus.add(er);
			}
		}
		return result;
	}

	@IsTest
	static void test_Event_getCompletedDatetime() {
		Datetime completed = Datetime.now();
		Datetime voided = completed.addDays(-1);
		Datetime declined = completed.addDays(-2);
		EventService.Event e1 = new EventService.Event();
		e1.status = Envelope.STATUS_COMPLETED;
		e1.completed = StringUtils.formatDatetime(completed);
		e1.voided = StringUtils.formatDatetime(voided);
		e1.declined = StringUtils.formatDatetime(declined);
		EventService.Event e2 = new EventService.Event();
		e2.status = Envelope.STATUS_DECLINED;
		e2.completed = StringUtils.formatDatetime(completed);
		e2.voided = StringUtils.formatDatetime(voided);
		e2.declined = StringUtils.formatDatetime(declined);
		EventService.Event e3 = new EventService.Event();
		e3.status = Envelope.STATUS_VOIDED;
		e3.completed = StringUtils.formatDatetime(completed);
		e3.voided = StringUtils.formatDatetime(voided);
		e3.declined = StringUtils.formatDatetime(declined);

		Test.startTest();
		System.assertEquals(completed, e1.getCompletedDatetime());
		System.assertEquals(declined, e2.getCompletedDatetime());
		System.assertEquals(voided, e3.getCompletedDatetime());
		Test.stopTest();
	}

	@IsTest
	static void test_Database_queryEnvelopeOptions() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Envelope.Options o = new Envelope.Options(
				true,
				null,
				new Map<String, Map<String, Object>> {
					Envelope.STATUS_CREATED => new Map<String, Object> {
						'a' => 'a1',
						'b' => 1,
						'c' => false
					},
					Envelope.STATUS_VOIDED => new Map<String, Object> {
						'a' => 'a2',
						'b' => 2,
						'c' => true
					}
				},
				new Map<String, Map<String, Object>> {
					Recipient.STATUS_COMPLETED => new Map<String, Object> {
						'a' => 'a3',
						'b' => 3,
						'c' => false
					},
					Recipient.STATUS_SENT => new Map<String, Object> {
						'a' => 'a4',
						'b' => 4,
						'c' => true
					}
				});
			Envelope__c e1 = new Envelope__c(
				DocuSignId__c = UUID.randomUUID().toString(),
				Options__c = ' ');
			Envelope__c e2 = new Envelope__c(
				DocuSignId__c = UUID.randomUUID().toString(),
				Options__c = null);
			Envelope__c e3 = new Envelope__c(
				DocuSignId__c = UUID.randomUUID().toString(),
				Options__c = JSON.serialize(o));
			insert new List<Envelope__c> { e1, e2, e3 };
			Set<UUID> envelopeIds = new Set<UUID> {
				UUID.randomUUID(),
				UUID.parse(e1.DocuSignId__c),
				UUID.parse(e2.DocuSignId__c),
				UUID.parse(e3.DocuSignId__c)
			};

			Test.startTest();
			Map<UUID, Envelope.Options> result = EventService.DB.queryEnvelopeOptions(envelopeIds);
			Test.stopTest();

			System.assertNotEquals(null, result);
			UUID eId = UUID.parse(e3.DocuSignId__c);
			System.assertEquals(new Set<UUID> { eId }, result.keySet());
			Envelope.Options o1 = result.get(eId);
			System.assertNotEquals(null, o1);
			System.assertEquals(o.includeDefaultAutoPlaceTags, o1.includeDefaultAutoPlaceTags);
			System.assertEquals(null, o1.documentWriteBack);
			System.assertEquals(o.envelopeEventUpdates, o1.envelopeEventUpdates);
			System.assertEquals(o.recipientEventUpdates, o1.recipientEventUpdates);
		}
	}

	@IsTest
	static void test_getWriteBackMergeFields_undefined_events() {
		UUID envelopeId = UUID.randomUUID();
		Id sourceId = UserInfo.getUserId();

		Test.startTest();
		System.assertEquals(
			new Map<String, Object>(),
			EventService.getWriteBackMergeFields(null, null, sourceId));
		System.assertEquals(
			new Map<String, Object>(),
			EventService.getWriteBackMergeFields(null, envelopeId, null));
		Test.stopTest();
	}

	@IsTest
	static void test_getWriteBackMergeFields_error() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			UUID transactionId = UUID.randomUUID(), envelopeId = UUID.randomUUID();
			Id sourceId = UserInfo.getOrganizationId();

			Test.startTest();
			Map<String, Object> result = EventService.getWriteBackMergeFields(
				transactionId,
				envelopeId,
				sourceId);
			Test.stopTest();

			System.assert(Collection.isEmpty(result));

			System.assertEquals(1, Collection.size(LoggerService.getInstance().logEntries));
			LoggerService.LogEntry le = LoggerService.getInstance().logEntries[0];
			System.assertNotEquals(null, le);
			System.assertNotEquals(null, le.context);
			System.assertEquals(transactionId, le.context.transactionId);
			System.assertEquals(envelopeId, le.context.entityId);
			System.assertEquals(sourceId, le.context.sourceId);
			System.assert(String.isNotBlank(le.message));
			System.assertEquals(String.valueOf(EventService.class), le.context.className);
			System.assertEquals('getWriteBackMergeFields', le.context.methodName);
		}
	}

	@IsTest
	static void test_getWriteBackMergeFields_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			UUID transactionId = UUID.randomUUID(), envelopeId = UUID.randomUUID();
			Id sourceId = UserInfo.getOrganizationId();

			Test.startTest();
			Map<String, Object> result = EventService.getWriteBackMergeFields(
				transactionId,
				envelopeId,
				sourceId);
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
			System.assertEquals(0, Collection.size(LoggerService.getInstance().logEntries));
		}
	}

	@IsTest
	static void test_buildMergeFieldUpdates_undefined_events() {
		Test.startTest();
		System.assertEquals(
			new Map<UUID, List<EventService.EnvelopeUpdates>>(),
			EventService.buildMergeFieldUpdates(null, null));
		System.assertEquals(
			new Map<UUID, List<EventService.EnvelopeUpdates>>(),
			EventService.buildMergeFieldUpdates(null, new List<EventService.Event>()));
		Test.stopTest();
	}

	@IsTest
	static void test_buildMergeFieldUpdates_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			UUID e1Id = UUID.randomUUID(),
				e2Id = UUID.randomUUID(),
				e3Id = UUID.randomUUID(),
				e4Id = UUID.randomUUID();
			EventService.Event e1 = createEvent(e1Id, Envelope.STATUS_SENT, UserInfo.getUserId());
			EventService.Event e2 = createEvent(e2Id, Envelope.STATUS_COMPLETED, null);
			EventService.Event e3 = createEvent(e3Id, Envelope.STATUS_VOIDED, null);
			EventService.Event e4 = createEvent(e1Id, Envelope.STATUS_COMPLETED, UserInfo.getUserId());
			EventService.Event e5 = createEvent(e4Id, Envelope.STATUS_COMPLETED, UserInfo.getOrganizationId());
			// Only events with valid source IDs should be counted: e1, e4, e5
			List<EventService.Event> events = new List<EventService.Event> {
				e1, e2, e3, e4, e5
			};

			Test.startTest();
			Map<UUID, List<EventService.EnvelopeUpdates>> result = EventService.buildMergeFieldUpdates(
				null,
				events);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(new Set<UUID> { e1Id, e2Id, e3Id, e4Id }, result.keySet());

			List<EventService.EnvelopeUpdates> eus = result.get(e1Id);
			System.assertNotEquals(null, eus);
			System.assertEquals(2, Collection.size(eus));

			EventService.EnvelopeUpdates eu = eus[0];
			System.assertNotEquals(null, eu);
			System.assertEquals(e1Id, eu.id);
			System.assertEquals(UserInfo.getUserId(), eu.sourceId);
			System.assertEquals(Envelope.STATUS_SENT, eu.status);
			System.assertEquals(new Map<String, Object>(), eu.updates);

			eu = eus[1];
			System.assertNotEquals(null, eu);
			System.assertEquals(e1Id, eu.id);
			System.assertEquals(UserInfo.getUserId(), eu.sourceId);
			System.assertEquals(Envelope.STATUS_COMPLETED, eu.status);
			System.assert(Collection.isNotEmpty(eu.updates));

			eus = result.get(e4Id);
			System.assertEquals(1, Collection.size(eus));

			eu = eus[0];
			System.assertNotEquals(null, eu);
			System.assertEquals(e4Id, eu.id);
			System.assertEquals(UserInfo.getOrganizationId(), eu.sourceId);
			System.assertEquals(Envelope.STATUS_COMPLETED, eu.status);
			System.assert(Collection.isNotEmpty(eu.updates));
		}
	}

	@IsTest
	static void test_mergeEnvelopeOptions_undefined_updates() {
		Test.startTest();
		System.assertEquals(
			new Map<UUID, List<EventService.EnvelopeUpdates>>(),
			EventService.mergeEnvelopeOptions(null));
		System.assertEquals(
			new Map<UUID, List<EventService.EnvelopeUpdates>>(),
			EventService.mergeEnvelopeOptions(new Map<UUID, List<EventService.EnvelopeUpdates>>()));
		Test.stopTest();
	}

	@IsTest
	static void test_mergeEnvelopeOptions_undefined_options() {
		UUID eId = UUID.randomUUID();
		Envelope__c e = new Envelope__c(
			DocuSignId__c = String.valueOf(eId),
			Options__c = JSON.serialize(new Envelope.Options(
				true,
				null,
				null,
				null)));
		insert e;
		Map<UUID, List<EventService.EnvelopeUpdates>> envelopeUpdates =
			new Map<UUID, List<EventService.EnvelopeUpdates>> {
				eId => new List<EventService.EnvelopeUpdates> {
					new EventService.EnvelopeUpdates(
						eId,
						UserInfo.getUserId(),
						Envelope.STATUS_SENT,
						null,
						new Map<String, List<EventService.RecipientUpdates>> {
							Recipient.STATUS_SENT => new List<EventService.RecipientUpdates> {
								new EventService.RecipientUpdates(
									UUID.randomUUID(),
									UserInfo.getUserId(),
									null)
							}
						}),
					new EventService.EnvelopeUpdates(
						eId,
						UserInfo.getUserId(),
						Envelope.STATUS_COMPLETED,
						new Map<String, Object> {
							'xx' => 'xx1',
							'yy' => 'yy1'
						},
						new Map<String, List<EventService.RecipientUpdates>> {
							Recipient.STATUS_COMPLETED => new List<EventService.RecipientUpdates> {
								new EventService.RecipientUpdates(
									UUID.randomUUID(),
									UserInfo.getUserId(),
									null)
							}
						})
				}
			};

		Test.startTest();
		Map<UUID, List<EventService.EnvelopeUpdates>> result = EventService.mergeEnvelopeOptions(envelopeUpdates);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<UUID> { eId }, result.keySet());

		List<EventService.EnvelopeUpdates> eus = result.get(eId);
		System.assertNotEquals(null, eus);
		System.assertEquals(2, Collection.size(eus));

		EventService.EnvelopeUpdates eu = eus[0];
		System.assertNotEquals(null, eu);
		System.assertEquals(eId, eu.id);
		System.assertEquals(UserInfo.getUserId(), eu.sourceId);
		System.assertEquals(Envelope.STATUS_SENT, eu.status);
		System.assertEquals(new Map<String, Object>(), eu.updates);

		eu = eus[1];
		System.assertNotEquals(null, eu);
		System.assertEquals(eId, eu.id);
		System.assertEquals(UserInfo.getUserId(), eu.sourceId);
		System.assertEquals(Envelope.STATUS_COMPLETED, eu.status);
		System.assertEquals(new Map<String, Object> {
			'xx' => 'xx1',
			'yy' => 'yy1'
		}, eu.updates);
	}

	@IsTest
	static void test_mergeEnvelopeOptions_success() {
		UUID eId1 = UUID.randomUUID(),
			eId2 = UUID.randomUUID(),
			eId3 = UUID.randomUUID();
		Envelope__c e1 = new Envelope__c(
			DocuSignId__c = String.valueOf(eId1),
			Options__c = JSON.serialize(new Envelope.Options(
				true,
				null,
				new Map<String, Map<String, Object>> {
					Envelope.STATUS_SENT => new Map<String, Object> {
						'a' => 'a1'
					},
					Envelope.STATUS_COMPLETED => new Map<String, Object> {
						'b' => 'b1',
						'c' => 'c1'
					}
				},
				new Map<String, Map<String, Object>> {
					Recipient.STATUS_DELIVERED => new Map<String, Object> {
						'd' => 'd1',
						'e' => 'e1'
					},
					Recipient.STATUS_COMPLETED => new Map<String, Object> {
						'f' => 'f1'
					}
				})));
		Envelope__c e2 = new Envelope__c(
			DocuSignId__c = String.valueOf(eId2),
			Options__c = null);
		Envelope__c e3 = new Envelope__c(
			DocuSignId__c = String.valueOf(eId3),
			Options__c = JSON.serialize(new Envelope.Options(
				true,
				null,
				new Map<String, Map<String, Object>> {
					Envelope.STATUS_VOIDED => new Map<String, Object> {
						'd' => 'd1',
						'e' => 'e1',
						'f' => 'f1'
					}
				},
				null)));
		insert new List<Envelope__c> { e1, e2, e3 };
		Map<UUID, List<EventService.EnvelopeUpdates>> envelopeUpdates
			= new Map<UUID, List<EventService.EnvelopeUpdates>> {
				eId1 => new List<EventService.EnvelopeUpdates> {
					new EventService.EnvelopeUpdates(
						eId1,
						UserInfo.getUserId(),
						Envelope.STATUS_SENT,
						null,
						new Map<String, List<EventService.RecipientUpdates>> {
							Recipient.STATUS_SENT => new List<EventService.RecipientUpdates> {
								new EventService.RecipientUpdates(
									UUID.randomUUID(),
									UserInfo.getUserId(),
									null)
							},
							Recipient.STATUS_DELIVERED => new List<EventService.RecipientUpdates> {
								new EventService.RecipientUpdates(
									UUID.randomUUID(),
									UserInfo.getUserId(),
									null)
							},
							Recipient.STATUS_COMPLETED => new List<EventService.RecipientUpdates> {
								new EventService.RecipientUpdates(
									UUID.randomUUID(),
									UserInfo.getUserId(),
									null),
								new EventService.RecipientUpdates(
									UUID.randomUUID(),
									UserInfo.getUserId(),
									null)
							}
						}),
					new EventService.EnvelopeUpdates(
						eId1,
						UserInfo.getUserId(),
						Envelope.STATUS_COMPLETED,
						new Map<String, Object> {
							'xx' => 'xx1',
							'yy' => 'yy1'
						},
						new Map<String, List<EventService.RecipientUpdates>> {
							Recipient.STATUS_COMPLETED => new List<EventService.RecipientUpdates> {
								new EventService.RecipientUpdates(
									UUID.randomUUID(),
									UserInfo.getUserId(),
									null),
								new EventService.RecipientUpdates(
									UUID.randomUUID(),
									UserInfo.getUserId(),
									null),
								new EventService.RecipientUpdates(
									UUID.randomUUID(),
									UserInfo.getUserId(),
									null),
								new EventService.RecipientUpdates(
									UUID.randomUUID(),
									UserInfo.getUserId(),
									null)
							}
						})
				},
				eId2 => new List<EventService.EnvelopeUpdates> {
					new EventService.EnvelopeUpdates(
						eId2,
						UserInfo.getOrganizationId(),
						Envelope.STATUS_COMPLETED,
						new Map<String, Object> {
							'z' => 'z1'
						},
						null)
				},
				eId3 => new List<EventService.EnvelopeUpdates> {
					new EventService.EnvelopeUpdates(
						eId3,
						UserInfo.getOrganizationId(),
						Envelope.STATUS_VOIDED,
						new Map<String, Object>(),
						new Map<String, List<EventService.RecipientUpdates>> {
							Recipient.STATUS_SENT => new List<EventService.RecipientUpdates> {
								new EventService.RecipientUpdates(
									UUID.randomUUID(),
									UserInfo.getUserId(),
									null),
								new EventService.RecipientUpdates(
									UUID.randomUUID(),
									UserInfo.getUserId(),
									null)
							}
						})
				}
			};

		Test.startTest();
		Map<UUID, List<EventService.EnvelopeUpdates>> result = EventService.mergeEnvelopeOptions(envelopeUpdates);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new Set<UUID> { eId1, eId2, eId3 }, result.keySet());

		List<EventService.EnvelopeUpdates> eus = result.get(eId1);
		System.assertEquals(2, Collection.size(eus));

		EventService.EnvelopeUpdates eu = eus[0];
		System.assertNotEquals(null, eu);
		System.assertEquals(eId1, eu.id);
		System.assertEquals(UserInfo.getUserId(), eu.sourceId);
		System.assertEquals(Envelope.STATUS_SENT, eu.status);
		System.assertEquals(new Map<String, Object> { 'a' => 'a1' }, eu.updates);

		System.assertNotEquals(null, eu.recipients);
		System.assertEquals(
			new Set<String> { Recipient.STATUS_SENT, Recipient.STATUS_DELIVERED, Recipient.STATUS_COMPLETED },
			eu.recipients.keySet());

		System.assertNotEquals(null, eu.recipients.get(Recipient.STATUS_SENT));
		System.assertEquals(1, Collection.size(eu.recipients.get(Recipient.STATUS_SENT)));
		System.assertNotEquals(null, eu.recipients.get(Recipient.STATUS_SENT)[0]);
		System.assertEquals(
			new Map<String, Object>(),
			eu.recipients.get(Recipient.STATUS_SENT)[0].updates);

		System.assertNotEquals(null, eu.recipients.get(Recipient.STATUS_DELIVERED));
		System.assertEquals(1, Collection.size(eu.recipients.get(Recipient.STATUS_DELIVERED)));
		System.assertNotEquals(null, eu.recipients.get(Recipient.STATUS_DELIVERED)[0]);
		System.assertEquals(
			new Map<String, Object> { 'd' => 'd1', 'e' => 'e1' },
			eu.recipients.get(Recipient.STATUS_DELIVERED)[0].updates);

		System.assertNotEquals(null, eu.recipients.get(Recipient.STATUS_COMPLETED));
		System.assertEquals(2, Collection.size(eu.recipients.get(Recipient.STATUS_COMPLETED)));
		for (EventService.RecipientUpdates ru : eu.recipients.get(Recipient.STATUS_COMPLETED)) {
			System.assertNotEquals(null, ru);
			System.assertEquals(new Map<String, Object> { 'f' => 'f1' }, ru.updates);
		}

		eu = eus[1];
		System.assertNotEquals(null, eu);
		System.assertEquals(eId1, eu.id);
		System.assertEquals(UserInfo.getUserId(), eu.sourceId);
		System.assertEquals(Envelope.STATUS_COMPLETED, eu.status);
		System.assertEquals(new Map<String, Object> {
			'b' => 'b1',
			'c' => 'c1',
			'xx' => 'xx1',
			'yy' => 'yy1'
		}, eu.updates);

		System.assertNotEquals(null, eu.recipients);
		System.assertEquals(new Set<String> { Recipient.STATUS_COMPLETED }, eu.recipients.keySet());

		System.assertNotEquals(null, eu.recipients.get(Recipient.STATUS_COMPLETED));
		System.assertEquals(4, Collection.size(eu.recipients.get(Recipient.STATUS_COMPLETED)));
		for (EventService.RecipientUpdates ru : eu.recipients.get(Recipient.STATUS_COMPLETED)) {
			System.assertNotEquals(null, ru);
			System.assertEquals(new Map<String, Object> { 'f' => 'f1' }, ru.updates);
		}

		eus = result.get(eId2);
		System.assertEquals(1, Collection.size(eus));

		eu = eus[0];
		System.assertNotEquals(null, eu);
		System.assertEquals(eId2, eu.id);
		System.assertEquals(UserInfo.getOrganizationId(), eu.sourceId);
		System.assertEquals(Envelope.STATUS_COMPLETED, eu.status);
		System.assertEquals(new Map<String, Object> { 'z' => 'z1' }, eu.updates);
		System.assert(Collection.isEmpty(eu.recipients));

		eus = result.get(eId3);
		System.assertEquals(1, Collection.size(eus));

		eu = eus[0];
		System.assertNotEquals(null, eu);
		System.assertEquals(eId3, eu.id);
		System.assertEquals(UserInfo.getOrganizationId(), eu.sourceId);
		System.assertEquals(Envelope.STATUS_VOIDED, eu.status);
		System.assertEquals(new Map<String, Object> {
			'd' => 'd1',
			'e' => 'e1',
			'f' => 'f1'
		}, eu.updates);

		System.assertNotEquals(null, eu.recipients);
		System.assertEquals(new Set<String> { Recipient.STATUS_SENT }, eu.recipients.keySet());

		System.assertNotEquals(null, eu.recipients.get(Recipient.STATUS_SENT));
		System.assertEquals(2, Collection.size(eu.recipients.get(Recipient.STATUS_SENT)));
		for (EventService.RecipientUpdates ru : eu.recipients.get(Recipient.STATUS_SENT)) {
			System.assertNotEquals(null, ru);
			System.assertEquals(new Map<String, Object>(), ru.updates);
		}
	}

	@IsTest
	static void test_updateData_undefined_arguments() {
		UUID envelopeId = UUID.randomUUID();
		Id sourceId = UserInfo.getUserId();
		Map<String, Object> dataUpdates = new Map<String, Object> { 'a' => 1 };
		UUID transactionId = null;

		Test.startTest();
		System.assertEquals(false, EventService.updateData(
			transactionId,
			null,
			sourceId,
			dataUpdates));
		System.assertEquals(false, EventService.updateData(
			transactionId,
			UUID.empty,
			sourceId,
			dataUpdates));
		System.assertEquals(false, EventService.updateData(
			transactionId,
			envelopeId,
			null,
			dataUpdates));
		System.assertEquals(true, EventService.updateData(
			transactionId,
			envelopeId,
			sourceId,
			null));
		System.assertEquals(true, EventService.updateData(
			transactionId,
			envelopeId,
			sourceId,
			new Map<String, Object>()));
		Test.stopTest();
	}

	@IsTest
	static void test_updateData_failure() {
		System.runAs(UserMock.createUser()) { // unauthorized for update
			LogSettings__c s = LogSettings__c.getInstance();
			s.Level__c = LoggingLevel.WARN.name();
			insert s;
			Envelope__c e = TestUtils.createEnvelope();
			UUID envelopeId = UUID.parse(e.DocuSignId__c);
			Id sourceId = e.Id;
			Map<String, Object> dataUpdates = new Map<String, Object> {
				Application.namespacePrefix + 'EmailMessage__c' => UUID.randomUUID().toString()
			};
			UUID transactionId = UUID.randomUUID();

			Test.startTest();
			System.assert(!EventService.updateData(
				transactionId,
				envelopeId,
				sourceId,
				dataUpdates));
			Test.stopTest();

			System.assertEquals(1, [SELECT COUNT() FROM Envelope__c WHERE Id = :e.Id]);

			System.assertEquals(1, Collection.size(LoggerService.getInstance().logEntries));
			LoggerService.LogEntry le = LoggerService.getInstance().logEntries[0];
			System.assertNotEquals(null, le);
			System.assertNotEquals(null, le.context);
			System.assertEquals(transactionId, le.context.transactionId);
			System.assertEquals(envelopeId, le.context.entityId);
			System.assertEquals(sourceId, le.context.sourceId);
			System.assert(String.isNotBlank(le.message));
			System.assertEquals(String.valueOf(EventService.class), le.context.className);
			System.assertEquals('updateData', le.context.methodName);
		}
	}

	@IsTest
	static void test_updateData_success() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Envelope__c e = TestUtils.createEnvelope();
			UUID envelopeId = UUID.parse(e.DocuSignId__c);
			Id sourceId = e.Id;
			Map<String, Object> dataUpdates = new Map<String, Object> {
				Application.namespacePrefix + 'EmailMessage__c' => UUID.randomUUID().toString()
			};
			UUID transactionId = UUID.randomUUID();

			Test.startTest();
			System.assert(EventService.updateData(
				transactionId,
				envelopeId,
				sourceId,
				dataUpdates));
			Test.stopTest();

			System.assertEquals(1, [SELECT COUNT() FROM Envelope__c WHERE Id = :e.Id]);
		}
	}

	@IsTest
	static void test_writeBackData_undefined_events() {
		Test.startTest();
		System.assertEquals(
			new List<EventService.EnvelopeUpdates>(),
			EventService.writeBackData(null, null));
		System.assertEquals(
			new List<EventService.EnvelopeUpdates>(),
			EventService.writeBackData(null, new List<EventService.Event>()));
		Test.stopTest();
	}

	@IsTest
	static void test_writeBackData_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Schema.Account a1 = TestUtils.createAccount();
			Schema.Account a2 = TestUtils.createAccount();
			Opportunity o1 = TestUtils.createOpportunity(a1.Id);
			Opportunity o2 = TestUtils.createOpportunity(a2.Id);
			Contact a1c1 = TestUtils.createContact(a1.Id);
			Contact a1c2 = TestUtils.createContact(a1.Id);
			Envelope.Options eo1 = new Envelope.Options(
				false,
				null,
				new Map<String, Map<String, Object>> {
					Envelope.STATUS_SENT => new Map<String, Object> {
						'Opportunity.Name' => 'e1.o1.STATUS_SENT',
						'Opportunity.Account.Name' => 'e1.o1.a1.STATUS_SENT'
					},
					Envelope.STATUS_DECLINED => new Map<String, Object> {
						'Opportunity.Name' => 'e1.o.STATUS_DECLINED',
						'Opportunity.Account.Name' => 'e1.o1.a1.STATUS_DECLINED'
					},
					Envelope.STATUS_COMPLETED => new Map<String, Object> {
						'Opportunity.Name' => 'e1.o1.STATUS_COMPLETED',
						'Opportunity.Account.Name' => 'e1.o1.a1.STATUS_COMPLETED'
					}
				},
				new Map<String, Map<String, Object>> {
					Recipient.STATUS_COMPLETED => new Map<String, Object> {
						'Contact.FirstName' => 'e1.a1c*.STATUS_DELIVERED'
					},
					Recipient.STATUS_COMPLETED => new Map<String, Object> {
						'Contact.FirstName' => 'e1.a1c*.STATUS_COMPLETED'
					}
				});
			Envelope__c e1 = TestUtils.createEnvelope(o1.Id, UUID.randomUUID(), eo1);
			Recipient__c e1r1 = TestUtils.createEnvelopeRecipient(e1.Id, 1, a1c1);
			Recipient__c e1r2 = TestUtils.createEnvelopeRecipient(e1.Id, 2, a1c2);
			Envelope.Options eo2 = new Envelope.Options(
				false,
				null,
				new Map<String, Map<String, Object>> {
					Envelope.STATUS_VOIDED => new Map<String, Object> {
						'Opportunity.Name' => 'e2.o2.STATUS_VOIDED',
						'Opportunity.Account.Name' => 'e2.o2.a2.STATUS_VOIDED'
					},
					Envelope.STATUS_COMPLETED => new Map<String, Object> {
						'Opportunity.Name' => 'e2.o2.STATUS_COMPLETED',
						'Opportunity.Account.Name' => 'e2.o2.a2.STATUS_COMPLETED'
					}
				},
				null);
			Envelope__c e2 = TestUtils.createEnvelope(o2.Id, UUID.randomUUID(), eo2);
			Recipient__c e2r1 = TestUtils.createEnvelopeRecipient(e2.Id, 1, TestUtils.createContact(a2.Id));
			Recipient__c e2r2 = TestUtils.createEnvelopeRecipient(e2.Id, 2, TestUtils.createContact(a2.Id));
			Recipient__c e2r3 = TestUtils.createEnvelopeRecipient(e2.Id, 3, TestUtils.createContact(a2.Id));
			EventService.Event evt1 = createEvent(
				e1,
				Envelope.STATUS_SENT,
				new Map<Recipient__c, String> {
					e1r1 => Recipient.STATUS_SENT,
					e1r2 => Recipient.STATUS_CREATED
				});
			EventService.Event evt2 = createEvent(
				e2,
				Envelope.STATUS_DELIVERED,
				new Map<Recipient__c, String> {
					e2r1 => Recipient.STATUS_DELIVERED,
					e2r2 => Recipient.STATUS_CREATED,
					e2r3 => Recipient.STATUS_CREATED
				});
			EventService.Event evt3 = createEvent(
				e1,
				Envelope.STATUS_DELIVERED,
				new Map<Recipient__c, String> {
					e1r1 => Recipient.STATUS_DELIVERED,
					e1r2 => Recipient.STATUS_CREATED
				});
			EventService.Event evt4 = createEvent( // final state for e2
				e2,
				Envelope.STATUS_VOIDED,
				new Map<Recipient__c, String> {
					e2r1 => Recipient.STATUS_COMPLETED,
					e2r2 => Recipient.STATUS_DELIVERED,
					e2r3 => Recipient.STATUS_CREATED
				});
			EventService.Event evt5 = createEvent( // final state for e1
				e1,
				Envelope.STATUS_COMPLETED,
				new Map<Recipient__c, String> {
					e1r1 => Recipient.STATUS_COMPLETED,
					e1r2 => Recipient.STATUS_COMPLETED
				});
			List<EventService.Event> events = new List<EventService.Event> {
				evt1, evt2, evt3, evt4, evt5
			};

			Test.startTest();
			List<EventService.EnvelopeUpdates> result = EventService.writeBackData(
				null,
				events);
			Test.stopTest();

			System.assertEquals(5, Collection.size(result));

			System.assertEquals('e1.o1.STATUS_COMPLETED', [SELECT Name FROM Opportunity WHERE Id = :o1.Id].Name);
			System.assertEquals('e1.o1.a1.STATUS_COMPLETED', [SELECT Name FROM Account WHERE Id = :a1.Id].Name);
			System.assertEquals('e1.a1c*.STATUS_COMPLETED', [SELECT FirstName FROM Contact WHERE Id = :a1c1.Id].FirstName);
			System.assertEquals('e1.a1c*.STATUS_COMPLETED', [SELECT FirstName FROM Contact WHERE Id = :a1c2.Id].FirstName);
			System.assertEquals('e2.o2.STATUS_VOIDED', [SELECT Name FROM Opportunity WHERE Id = :o2.Id].Name);
			System.assertEquals('e2.o2.a2.STATUS_VOIDED', [SELECT Name FROM Account WHERE Id = :a2.Id].Name);
		}
	}

	@IsTest
	static void test_updateStatus_undefined_events() {
		Test.startTest();
		System.assertEquals(
			true,
			EventService.updateStatus(null, null));
		System.assertEquals(
			true,
			EventService.updateStatus(null, new List<EventService.Event>()));
		Test.stopTest();
	}

	@IsTest
	static void test_updateStatus_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			LogSettings__c s = LogSettings__c.getInstance();
			s.Level__c = LoggingLevel.ERROR.name();
			insert s;
			Id sourceId = UserInfo.getOrganizationId();
			Envelope__c e = TestUtils.createEnvelope(sourceId);
			Recipient__c r = TestUtils.createEnvelopeRecipient(e.Id, 1);
			EventService.Event evt = createEvent(
				e,
				Envelope.STATUS_SENT,
				new Map<Recipient__c, String> {
					r => Recipient.STATUS_SENT
				});
			List<EventService.Event> events = new List<EventService.Event> { evt };
			UUID transactionId = UUID.randomUUID(), envelopeId = UUID.parse(e.DocuSignId__c);

			Test.startTest();
			System.assert(!EventService.updateStatus(transactionId, events));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateStatus_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Schema.Account a1 = TestUtils.createAccount();
			Schema.Account a2 = TestUtils.createAccount();
			Opportunity o1 = TestUtils.createOpportunity(a1.Id);
			Opportunity o2 = TestUtils.createOpportunity(a2.Id);
			Envelope__c e1 = TestUtils.createEnvelope(o1.Id);
			Recipient__c e1r1 = TestUtils.createEnvelopeRecipient(e1.Id, 1, TestUtils.createContact(a1.Id));
			Recipient__c e1r2 = TestUtils.createEnvelopeRecipient(e1.Id, 2, TestUtils.createContact(a1.Id));
			Envelope__c e2 = TestUtils.createEnvelope(o2.Id);
			Recipient__c e2r1 = TestUtils.createEnvelopeRecipient(e2.Id, 1, TestUtils.createContact(a2.Id));
			Recipient__c e2r2 = TestUtils.createEnvelopeRecipient(e2.Id, 2, TestUtils.createContact(a2.Id));
			Recipient__c e2r3 = TestUtils.createEnvelopeRecipient(e2.Id, 3, TestUtils.createContact(a2.Id));
			EnvelopeStatus__c es1 = TestUtils.createEnvelopeStatus(e1);
			TestUtils.createRecipientStatus(es1.Id, e1r1);
			TestUtils.createRecipientStatus(es1.Id, e1r2);
			// No status for e2--should create
			EventService.Event evt1 = createEvent(
				e1,
				Envelope.STATUS_SENT,
				new Map<Recipient__c, String> {
					e1r1 => Recipient.STATUS_SENT,
					e1r2 => Recipient.STATUS_CREATED
				});
			EventService.Event evt2 = createEvent(
				e2,
				Envelope.STATUS_DELIVERED,
				new Map<Recipient__c, String> {
					e2r1 => Recipient.STATUS_DELIVERED,
					e2r2 => Recipient.STATUS_CREATED,
					e2r3 => Recipient.STATUS_CREATED
				});
			EventService.Event evt3 = createEvent(
				e1,
				Envelope.STATUS_DELIVERED,
				new Map<Recipient__c, String> {
					e1r1 => Recipient.STATUS_DELIVERED,
					e1r2 => Recipient.STATUS_CREATED
				});
			EventService.Event evt4 = createEvent( // final state for e2
				e2,
				Envelope.STATUS_VOIDED,
				new Map<Recipient__c, String> {
					e2r1 => Recipient.STATUS_COMPLETED,
					e2r2 => Recipient.STATUS_DELIVERED,
					e2r3 => Recipient.STATUS_CREATED
				});
			EventService.Event evt5 = createEvent( // final state for e1
				e1,
				Envelope.STATUS_COMPLETED,
				new Map<Recipient__c, String> {
					e1r1 => Recipient.STATUS_COMPLETED,
					e1r2 => Recipient.STATUS_COMPLETED
				});
			List<EventService.Event> events = new List<EventService.Event> {
				evt1, evt2, evt3, evt4, evt5
			};

			Test.startTest();
			System.assert(EventService.updateStatus(null, events));
			Test.stopTest();

			List<EnvelopeStatus__c> ess = [
				SELECT Id, DocuSignId__c, Status__c, SourceId__c
				FROM EnvelopeStatus__c
				WHERE DocuSignId__c IN :NEW Set<String> { e1.DocuSignId__c, e2.DocuSignId__c }
			];
			System.assertEquals(2, Collection.size(ess));
			Id es1Id, es2Id;
			for (EnvelopeStatus__c es : ess) {
				if (es.DocuSignId__c == e1.DocuSignId__c) {
					System.assertEquals(Envelope.STATUS_COMPLETED, es.Status__c);
					System.assertEquals(e1.SourceId__c, es.SourceId__c);
					es1Id = es.Id;
				} else if (es.DocuSignId__c == e2.DocuSignId__c) {
					System.assertEquals(Envelope.STATUS_VOIDED, es.Status__c);
					System.assertEquals(e2.SourceId__c, es.SourceId__c);
					es2Id = es.Id;
				} else {
					throw new AssertException('Unexpected envelope status: ' + es);
				}
			}

			List<RecipientStatus__c> rss = [
				SELECT Id, EnvelopeStatus__c, Status__c, Type__c, Email__c, Name, SourceId__c
				FROM RecipientStatus__c
				WHERE EnvelopeStatus__c IN :NEW Set<Id> { es1Id, es2Id }
			];
			System.assertEquals(5, Collection.size(rss));
			for (RecipientStatus__c rs : rss) {
				Recipient__c expected;
				if (rs.Name == e1r1.Name) {
					expected = e1r1;
					System.assertEquals(Recipient.STATUS_COMPLETED, rs.Status__c);
					System.assertEquals(es1Id, rs.EnvelopeStatus__c);
				} else if (rs.Name == e1r2.Name) {
					expected = e1r2;
					System.assertEquals(Recipient.STATUS_COMPLETED, rs.Status__c);
					System.assertEquals(es1Id, rs.EnvelopeStatus__c);
				} else if (rs.Name == e2r1.Name) {
					expected = e2r1;
					System.assertEquals(Recipient.STATUS_COMPLETED, rs.Status__c);
					System.assertEquals(es2Id, rs.EnvelopeStatus__c);
				} else if (rs.Name == e2r2.Name) {
					expected = e2r2;
					System.assertEquals(Recipient.STATUS_DELIVERED, rs.Status__c);
					System.assertEquals(es2Id, rs.EnvelopeStatus__c);
				} else if (rs.Name == e2r3.Name) {
					expected = e2r3;
					System.assertEquals(Recipient.STATUS_CREATED, rs.Status__c);
					System.assertEquals(es2Id, rs.EnvelopeStatus__c);
				} else {
					throw new AssertException('Unexpected recipient status: ' + rs);
				}
				System.assertEquals(expected.Type__c, rs.Type__c);
				System.assertEquals(expected.Email__c, rs.Email__c);
				System.assertEquals(expected.SourceId__c, rs.SourceId__c);
			}
		}
	}

	@IsTest
	static void test_getErrorResponse_null() {
		UUID transactionId = UUID.randomUUID();

		Test.startTest();
		EventService.Response result = EventService.getErrorResponse(
			transactionId,
			null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(String.valueOf(transactionId), result.transactionId);
		System.assertEquals(500, result.status);
		System.assertNotEquals(null, result.error);
		System.assertEquals(APIErrorCode.FAILURE, result.error.code);
		System.assertEquals(null, result.error.type);
		System.assertEquals(Label.UnknownError, result.error.message);
	}

	@IsTest
	static void test_getErrorResponse_RequestException() {
		UUID transactionId = UUID.randomUUID();
		EventService.RequestException ex = new EventService.RequestException(
			TestUtils.randomInteger(10000),
			UUID.randomUUID().toString());

		Test.startTest();
		EventService.Response result = EventService.getErrorResponse(
			transactionId,
			ex);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(String.valueOf(transactionId), result.transactionId);
		System.assertEquals(400, result.status);
		System.assertNotEquals(null, result.error);
		System.assertEquals(ex.code, result.error.code);
		System.assertEquals(ex.getTypeName(), result.error.type);
		System.assertEquals(ex.getMessage(), result.error.message);
	}

	@IsTest
	static void test_getErrorResponse_UnauthorizedException() {
		UUID transactionId = UUID.randomUUID();
		UnauthorizedException ex = new UnauthorizedException(
			UUID.randomUUID().toString());

		Test.startTest();
		EventService.Response result = EventService.getErrorResponse(
			transactionId,
			ex);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(String.valueOf(transactionId), result.transactionId);
		System.assertEquals(401, result.status);
		System.assertNotEquals(null, result.error);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, result.error.code);
		System.assertEquals(ex.getTypeName(), result.error.type);
		System.assertEquals(Label.UnauthorizedOperation, result.error.message);
	}

	@IsTest
	static void test_getErrorResponse_JSONException() {
		UUID transactionId = UUID.randomUUID();
		JSONException ex = new JSONException(
			UUID.randomUUID().toString());

		Test.startTest();
		EventService.Response result = EventService.getErrorResponse(
			transactionId,
			ex);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(String.valueOf(transactionId), result.transactionId);
		System.assertEquals(400, result.status);
		System.assertNotEquals(null, result.error);
		System.assertEquals(APIErrorCode.INVALID_JSON, result.error.code);
		System.assertEquals(ex.getTypeName(), result.error.type);
		System.assertEquals(Label.InvalidJson, result.error.message);
	}

	@IsTest
	static void test_getErrorResponse_other() {
		UUID transactionId = UUID.randomUUID();
		Exception ex = new AssertException(
			UUID.randomUUID().toString());

		Test.startTest();
		EventService.Response result = EventService.getErrorResponse(
			transactionId,
			ex);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(String.valueOf(transactionId), result.transactionId);
		System.assertEquals(400, result.status);
		System.assertNotEquals(null, result.error);
		System.assertEquals(APIErrorCode.BAD_REQUEST, result.error.code);
		System.assertEquals(ex.getTypeName(), result.error.type);
		System.assertEquals(ex.getMessage(), result.error.message);
	}

	@IsTest
	static void test_publishEvents_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			LogSettings__c s = LogSettings__c.getInstance();
			s.Level__c = LoggingLevel.WARN.name();
			insert s;
			UUID transactionId = UUID.randomUUID();
			RestContext.request = new RestRequest();
			RestContext.request.httpMethod = 'PUT';
			if (String.isNotBlank(Application.namespace)) {
				RestContext.request.requestURI = '/services/apexrest/' + Application.namespace + '/v1/status';
			} else {
				RestContext.request.requestURI = '/services/apexrest/v1/status';
			}
			RestContext.request.addParameter(EventService.KEY_TRANSACTION_ID, String.valueOf(transactionId));
			RestContext.response = new RestResponse();

			Test.startTest();
			EventService.publishEvents();
			Test.stopTest();

			System.assertNotEquals(null, RestContext.response);
			System.assertEquals(401, RestContext.response.statusCode);
			System.assertNotEquals(null, RestContext.response.headers);
			System.assertEquals('application/json', RestContext.response.headers.get('Content-Type'));
			System.assertNotEquals(null, RestContext.response.responseBody);
			EventService.Response resp = (EventService.Response)JSON.deserialize(
				RestContext.response.responseBody.toString(),
				EventService.Response.class);
			System.assertNotEquals(null, resp);
			System.assertEquals(String.valueOf(transactionId), resp.transactionId);
			System.assertEquals(401, resp.status);
			System.assertNotEquals(null, resp.millisecondDuration);
			System.assertNotEquals(null, resp.error);
			System.assertEquals(APIErrorCode.UNAUTHORIZED, resp.error.code);
			System.assertEquals(String.valueOf(UnauthorizedException.class), resp.error.type);
			System.assertEquals(Label.UnauthorizedOperation, resp.error.message);

			List<Log__c> ls = [
				SELECT Id, TransactionId__c, EntityId__c, SourceId__c, Version__c, Severity__c, Message__c, Class__c,
					Method__c
				FROM Log__c
			];
			System.assertEquals(1, Collection.size(ls));
			LoggerService.LogEntry le = LoggerService.DB.convert(ls[0]);
			System.assertNotEquals(null, le);
			System.assertNotEquals(null, le.context);
			System.assertEquals(transactionId, le.context.transactionId);
			System.assertEquals(null, le.context.entityId);
			System.assertEquals(null, le.context.sourceId);
			System.assert(String.isNotBlank(le.message));
			System.assert(le.message.startsWith(Label.EventProcessingFailed));
			System.assertEquals(String.valueOf(EventService.class), le.context.className);
			System.assertEquals('publishEvents', le.context.methodName);
		}
	}

	@IsTest
	static void test_publishEvents_invalid_request() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			LogSettings__c s = LogSettings__c.getInstance();
			s.Level__c = LoggingLevel.WARN.name();
			insert s;
			UUID transactionId = UUID.randomUUID();
			RestContext.request = new RestRequest();
			RestContext.request.httpMethod = 'PUT';
			if (String.isNotBlank(Application.namespace)) {
				RestContext.request.requestURI = '/services/apexrest/' + Application.namespace + '/v1/status';
			} else {
				RestContext.request.requestURI = '/services/apexrest/v1/status';
			}
			RestContext.request.addParameter(EventService.KEY_TRANSACTION_ID, String.valueOf(transactionId));
			RestContext.response = new RestResponse();

			Test.startTest();
			EventService.publishEvents();
			Test.stopTest();

			System.assertNotEquals(null, RestContext.response);
			System.assertEquals(400, RestContext.response.statusCode);
			System.assertNotEquals(null, RestContext.response.headers);
			System.assertEquals('application/json', RestContext.response.headers.get('Content-Type'));
			System.assertNotEquals(null, RestContext.response.responseBody);
			EventService.Response resp = (EventService.Response)JSON.deserialize(
				RestContext.response.responseBody.toString(),
				EventService.Response.class);
			System.assertNotEquals(null, resp);
			System.assertEquals(String.valueOf(transactionId), resp.transactionId);
			System.assertEquals(400, resp.status);
			System.assertNotEquals(null, resp.millisecondDuration);
			System.assertNotEquals(null, resp.error);
			System.assertEquals(APIErrorCode.UNDEFINED_REQUEST_BODY, resp.error.code);
			System.assertEquals(String.valueOf(EventService.RequestException.class), resp.error.type);
			System.assertEquals(Label.UndefinedRequestBody, resp.error.message);

			List<Log__c> ls = [
				SELECT Id, TransactionId__c, EntityId__c, SourceId__c, Version__c, Severity__c, Message__c, Class__c,
					Method__c
				FROM Log__c
			];
			System.assertEquals(1, Collection.size(ls));
			LoggerService.LogEntry le = LoggerService.DB.convert(ls[0]);
			System.assertNotEquals(null, le);
			System.assertNotEquals(null, le.context);
			System.assertEquals(transactionId, le.context.transactionId);
			System.assertEquals(null, le.context.entityId);
			System.assertEquals(null, le.context.sourceId);
			System.assert(String.isNotBlank(le.message));
			System.assert(le.message.startsWith(Label.EventProcessingFailed));
			System.assertEquals(String.valueOf(EventService.class), le.context.className);
			System.assertEquals('publishEvents', le.context.methodName);
		}
	}

	@IsTest
	static void test_publishEvents_invalid_json() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			LogSettings__c s = LogSettings__c.getInstance();
			s.Level__c = LoggingLevel.WARN.name();
			insert s;
			UUID transactionId = UUID.randomUUID();
			RestContext.request = new RestRequest();
			RestContext.request.httpMethod = 'PUT';
			if (String.isNotBlank(Application.namespace)) {
				RestContext.request.requestURI = '/services/apexrest/' + Application.namespace + '/v1/status';
			} else {
				RestContext.request.requestURI = '/services/apexrest/v1/status';
			}
			RestContext.request.addParameter(EventService.KEY_TRANSACTION_ID, String.valueOf(transactionId));
			RestContext.request.requestBody = Blob.valueOf('invalid_json');
			RestContext.response = new RestResponse();

			Test.startTest();
			EventService.publishEvents();
			Test.stopTest();

			System.assertNotEquals(null, RestContext.response);
			System.assertEquals(400, RestContext.response.statusCode);
			System.assertNotEquals(null, RestContext.response.headers);
			System.assertEquals('application/json', RestContext.response.headers.get('Content-Type'));
			System.assertNotEquals(null, RestContext.response.responseBody);
			EventService.Response resp = (EventService.Response)JSON.deserialize(
				RestContext.response.responseBody.toString(),
				EventService.Response.class);
			System.assertNotEquals(null, resp);
			System.assertEquals(String.valueOf(transactionId), resp.transactionId);
			System.assertEquals(400, resp.status);
			System.assertNotEquals(null, resp.millisecondDuration);
			System.assertNotEquals(null, resp.error);
			System.assertEquals(APIErrorCode.INVALID_JSON, resp.error.code);
			System.assertEquals(String.valueOf(JSONException.class), resp.error.type);
			System.assertEquals(Label.InvalidJson, resp.error.message);

			List<Log__c> ls = [
				SELECT Id, TransactionId__c, EntityId__c, SourceId__c, Version__c, Severity__c, Message__c, Class__c,
					Method__c
				FROM Log__c
			];
			System.assertEquals(1, Collection.size(ls));
			LoggerService.LogEntry le = LoggerService.DB.convert(ls[0]);
			System.assertNotEquals(null, le);
			System.assertNotEquals(null, le.context);
			System.assertEquals(transactionId, le.context.transactionId);
			System.assertEquals(null, le.context.entityId);
			System.assertEquals(null, le.context.sourceId);
			System.assert(String.isNotBlank(le.message));
			System.assert(le.message.startsWith(Label.EventProcessingFailed));
			System.assertEquals(String.valueOf(EventService.class), le.context.className);
			System.assertEquals('publishEvents', le.context.methodName);
		}
	}

	@IsTest
	static void test_publishEvents_success() {
		// Updates can be partially successful with success response.
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Schema.Account a1 = TestUtils.createAccount();
			Schema.Account a2 = TestUtils.createAccount();
			Opportunity o1 = TestUtils.createOpportunity(a1.Id);
			Opportunity o2 = TestUtils.createOpportunity(a2.Id);
			Envelope.Options eo1 = new Envelope.Options(
				false,
				null,
				new Map<String, Map<String, Object>> {
					Envelope.STATUS_SENT => new Map<String, Object> {
						'Opportunity.Name' => 'e1.o1.STATUS_SENT',
						'Opportunity.Account.Name' => 'e1.o1.a1.STATUS_SENT'
					},
					Envelope.STATUS_DECLINED => new Map<String, Object> {
						'Opportunity.Name' => 'e1.o.STATUS_DECLINED',
						'Opportunity.Account.Name' => 'e1.o1.a1.STATUS_DECLINED'
					},
					Envelope.STATUS_COMPLETED => new Map<String, Object> {
						'Opportunity.Account.Invalid' => 'invalid', // invalid field
						'Opportunity.Invalid.Name' => 'invalid' // invalid relationship
					}
				},
				null); // FIXME: Wire up recipient events
			Envelope__c e1 = TestUtils.createEnvelope(o1.Id, UUID.randomUUID(), eo1);
			Recipient__c e1r1 = TestUtils.createEnvelopeRecipient(e1.Id, 1, TestUtils.createContact(a1.Id));
			Recipient__c e1r2 = TestUtils.createEnvelopeRecipient(e1.Id, 2, TestUtils.createContact(a1.Id));
			Envelope.Options eo2 = new Envelope.Options(
				false,
				null,
				new Map<String, Map<String, Object>> {
					Envelope.STATUS_VOIDED => new Map<String, Object> {
						'Opportunity.Name' => 'e2.o2.STATUS_VOIDED',
						'Opportunity.Account.Name' => false // invalid type
					},
					Envelope.STATUS_COMPLETED => new Map<String, Object> {
						'Opportunity.Name' => 'e2.o2.STATUS_COMPLETED',
						'Opportunity.Account.Name' => 'e2.o2.a2.STATUS_COMPLETED'
					}
				},
				null);
			Envelope__c e2 = TestUtils.createEnvelope(o2.Id, UUID.randomUUID(), eo2);
			Recipient__c e2r1 = TestUtils.createEnvelopeRecipient(e2.Id, 1, TestUtils.createContact(a2.Id));
			Recipient__c e2r2 = TestUtils.createEnvelopeRecipient(e2.Id, 2, TestUtils.createContact(a2.Id));
			Recipient__c e2r3 = TestUtils.createEnvelopeRecipient(e2.Id, 3, TestUtils.createContact(a2.Id));
			EventService.Event evt1 = createEvent(
				e1,
				Envelope.STATUS_SENT,
				new Map<Recipient__c, String> {
					e1r1 => Recipient.STATUS_SENT,
					e1r2 => Recipient.STATUS_CREATED
				});
			EventService.Event evt2 = createEvent(
				e2,
				Envelope.STATUS_DELIVERED,
				new Map<Recipient__c, String> {
					e2r1 => Recipient.STATUS_DELIVERED,
					e2r2 => Recipient.STATUS_CREATED,
					e2r3 => Recipient.STATUS_CREATED
				});
			EventService.Event evt3 = createEvent(
				e1,
				Envelope.STATUS_DELIVERED,
				new Map<Recipient__c, String> {
					e1r1 => Recipient.STATUS_DELIVERED,
					e1r2 => Recipient.STATUS_CREATED
				});
			EventService.Event evt4 = createEvent( // final state for e2
				e2,
				Envelope.STATUS_VOIDED,
				new Map<Recipient__c, String> {
					e2r1 => Recipient.STATUS_COMPLETED,
					e2r2 => Recipient.STATUS_DELIVERED,
					e2r3 => Recipient.STATUS_CREATED
				});
			EventService.Event evt5 = createEvent( // final state for e1
				e1,
				Envelope.STATUS_COMPLETED,
				new Map<Recipient__c, String> {
					e1r1 => Recipient.STATUS_COMPLETED,
					e1r2 => Recipient.STATUS_COMPLETED
				});
			EventService.EventWrapper ew1 = new EventService.EventWrapper();
			ew1.envelopeStatus = evt1;
			EventService.EventWrapper ew2 = new EventService.EventWrapper();
			ew2.envelopeStatus = evt2;
			EventService.EventWrapper ew3 = new EventService.EventWrapper();
			ew3.envelopeStatus = evt3;
			EventService.EventWrapper ew4 = new EventService.EventWrapper();
			ew4.envelopeStatus = evt4;
			EventService.EventWrapper ew5 = new EventService.EventWrapper();
			ew5.envelopeStatus = evt5;
			List<EventService.EventWrapper> events = new List<EventService.EventWrapper> {
				ew1, ew2, ew3, ew4, ew5
			};
			UUID transactionId = UUID.randomUUID();
			RestContext.request = new RestRequest();
			RestContext.request.httpMethod = 'PUT';
			if (String.isNotBlank(Application.namespace)) {
				RestContext.request.requestURI = '/services/apexrest/' + Application.namespace + '/v1/status';
			} else {
				RestContext.request.requestURI = '/services/apexrest/v1/status';
			}
			RestContext.request.addParameter(EventService.KEY_TRANSACTION_ID, String.valueOf(transactionId));
			RestContext.request.requestBody = Blob.valueOf(JSON.serialize(events));
			RestContext.response = new RestResponse();

			Test.startTest();
			EventService.publishEvents();
			Test.stopTest();

			System.assertNotEquals(null, RestContext.response);
			System.assertEquals(200, RestContext.response.statusCode);
			System.assertNotEquals(null, RestContext.response.headers);
			System.assertEquals('application/json', RestContext.response.headers.get('Content-Type'));
			System.assertNotEquals(null, RestContext.response.responseBody);
			EventService.Response resp = (EventService.Response)JSON.deserialize(
				RestContext.response.responseBody.toString(),
				EventService.Response.class);
			System.assertNotEquals(null, resp);
			System.assertEquals(String.valueOf(transactionId), resp.transactionId);
			System.assertEquals(200, resp.status);
			System.assertNotEquals(null, resp.millisecondDuration);
			System.assertEquals(null, resp.error);
			System.assertNotEquals(null, resp.results);
			System.assertEquals(5, resp.results.size());
			for (EventService.EnvelopeUpdates eus : resp.results) {
				if (eus.envelopeId == e1.DocuSignId__c) {
					if (eus.status == Envelope.STATUS_SENT) {
						System.assert(eus.success);
					} else if (eus.status == Envelope.STATUS_DELIVERED) {
						System.assert(eus.success);
					} else if (eus.status == Envelope.STATUS_COMPLETED) {
						System.assert(!eus.success);
					} else {
						throw new AssertException('Unexpected status: ' + eus.status);
					}
				} else if (eus.envelopeId == e2.DocuSignId__c) {
					if (eus.status == Envelope.STATUS_DELIVERED) {
						System.assert(eus.success);
					} else if (eus.status == Envelope.STATUS_VOIDED) {
						System.assert(!eus.success);
					} else {
						throw new AssertException('Unexpected status: ' + eus.status);
					}
				} else {
					throw new AssertException('Unexpected result: ' + eus);
				}
			}

			List<Log__c> ls = [
				SELECT Id, TransactionId__c, EntityId__c, SourceId__c, Version__c, Severity__c, Message__c, Class__c,
					Method__c
				FROM Log__c
			];
			System.assertEquals(2, Collection.size(ls));
			for (Log__c l : ls) {
				LoggerService.LogEntry le = LoggerService.DB.convert(l);
				System.assertNotEquals(null, le);
				System.assertNotEquals(null, le.context);
				System.assertEquals(transactionId, le.context.transactionId);
				System.assert(String.isNotBlank(le.message));
				System.assertEquals(String.valueOf(EventService.class), le.context.className);
			}
		}
	}
}
