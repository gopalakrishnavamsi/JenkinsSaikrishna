@IsTest
private class EnvelopeParserTest {

	@IsTest
	static void test_deserializeOptions() {
		Envelope.Options o = new Envelope.Options(
			false,
			new Envelope.DocumentWriteBack(
				UserInfo.getUserId(),
				'NamePDF',
				false,
				true),
			new Map<String, Map<String, Object>> {
				's1' => new Map<String, Object> {
					'n1' => true,
					'n2' => 3.99,
					'n3' => StringUtils.formatDatetime(Datetime.now()),
					'n4' => 'v4'
				},
				's2' => new Map<String, Object> {
					'n5' => 'v5'
				}
			},
			new Map<String, Map<String, Object>> {
				's3' => new Map<String, Object> {
					'n6' => 'v6'
				}
			});
		String optionsJson = JSON.serialize(o);

		Test.startTest();
		Envelope.Options result = EnvelopeParser.deserializeOptions(optionsJson);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(o.includeDefaultAutoPlaceTags, result.includeDefaultAutoPlaceTags);
		System.assertNotEquals(null, result.documentWriteBack);
		System.assertEquals(o.documentWriteBack.linkedEntityId, result.documentWriteBack.linkedEntityId);
		System.assertEquals(o.documentWriteBack.nameFormat, result.documentWriteBack.nameFormat);
		System.assertEquals(o.documentWriteBack.combineDocuments, result.documentWriteBack.combineDocuments);
		System.assertEquals(o.documentWriteBack.includeCertificateOfCompletion, result.documentWriteBack.includeCertificateOfCompletion);
		System.assertEquals(o.envelopeEventUpdates, result.envelopeEventUpdates);
		System.assertEquals(o.recipientEventUpdates, result.recipientEventUpdates);

	}

	@IsTest
	static void test_reifyOptions() {
		Envelope.Options o = new Envelope.Options(
			false,
			new Envelope.DocumentWriteBack(
				UserInfo.getUserId(),
				'NamePDF',
				false,
				true),
			new Map<String, Map<String, Object>> {
				's1' => new Map<String, Object> {
					'n1' => true,
					'n2' => 3.99,
					'n3' => StringUtils.formatDatetime(Datetime.now()),
					'n4' => 'v4'
				},
				's2' => new Map<String, Object> {
					'n5' => 'v5'
				}
			},
			new Map<String, Map<String, Object>> {
				's3' => new Map<String, Object> {
					'n6' => 'v6'
				}
			});
		Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(o));

		Test.startTest();
		Envelope.Options result = EnvelopeParser.reifyOptions(m);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(o.includeDefaultAutoPlaceTags, result.includeDefaultAutoPlaceTags);
		System.assertNotEquals(null, result.documentWriteBack);
		System.assertEquals(o.documentWriteBack.linkedEntityId, result.documentWriteBack.linkedEntityId);
		System.assertEquals(o.documentWriteBack.nameFormat, result.documentWriteBack.nameFormat);
		System.assertEquals(o.documentWriteBack.combineDocuments, result.documentWriteBack.combineDocuments);
		System.assertEquals(o.documentWriteBack.includeCertificateOfCompletion, result.documentWriteBack.includeCertificateOfCompletion);
		System.assertEquals(o.envelopeEventUpdates, result.envelopeEventUpdates);
		System.assertEquals(o.recipientEventUpdates, result.recipientEventUpdates);
	}

	static void compareDocument(final Document d1, final Document d2) {
		System.assertNotEquals(null, d2);
		System.assertEquals(d1.id, d2.id);
		System.assertEquals(d1.type, d2.type);
		System.assertEquals(d1.sequence, d2.sequence);
		System.assertEquals(d1.name, d2.name);
		System.assertEquals(d1.extension, d2.extension);
		System.assertEquals(d1.size, d2.size);
		System.assertEquals(d1.lastModified, d2.lastModified);
		System.assertEquals(d1.sourceId, d2.sourceId);
		System.assertEquals(d1.readOnly, d2.readOnly);
		System.assertEquals(d1.required, d2.required);
		System.assertEquals(Collection.size(d1.templateDocuments), Collection.size(d2.templateDocuments));
	}

	static void compareDocuments(final List<Document> ds1, final List<Document> ds2) {
		System.assertEquals(Collection.size(ds1), Collection.size(ds2));
		if (ds1 != null) {
			Map<String, Document> m = new Map<String, Document>();
			for (Document d : ds1) {
				m.put(d.name, d);
			}
			for (Document d2 : ds2) {
				System.assertNotEquals(null, d2);
				Document d1 = m.get(d2.name);
				System.assertNotEquals(null, d1);
				compareDocument(d1, d2);
			}
		}
	}

	static void compareRecipient(final Recipient r1, final Recipient r2) {
		System.assertNotEquals(null, r2);
		System.assertEquals(r1.id, r2.id);
		System.assertEquals(r1.envelopeRecipientId, r2.envelopeRecipientId);
		System.assertEquals(r1.type, r2.type);
		System.assertEquals(r1.sequence, r2.sequence);
		System.assertEquals(r1.routingOrder, r2.routingOrder);
		if (r1.role != null) {
			System.assertNotEquals(null, r2.role);
			System.assertEquals(r1.role.name, r2.role.name);
			System.assertEquals(r1.role.value, r2.role.value);
		}
		System.assertEquals(r1.name, r2.name);
		System.assertEquals(r1.email, r2.email);
		if (r1.signingGroup != null) {
			System.assertNotEquals(null, r2.signingGroup);
			System.assertEquals(r1.signingGroup.id, r2.signingGroup.id);
			System.assertEquals(r1.signingGroup.name, r2.signingGroup.name);
		}
		System.assertEquals(r1.phone, r2.phone);
		if (r1.authentication != null) {
			System.assertNotEquals(null, r2.authentication);
			System.assertEquals(r1.authentication.accessCode, r2.authentication.accessCode);
			System.assertEquals(r1.authentication.idCheckRequired, r2.authentication.idCheckRequired);
			System.assertEquals(r1.authentication.smsPhoneNumbers, r2.authentication.smsPhoneNumbers);
		}
		System.assertEquals(r1.hostName, r2.hostName);
		System.assertEquals(r1.hostEmail, r2.hostEmail);
		System.assertEquals(r1.signNow, r2.signNow);
		compareTabs(r1.tabs, r2.tabs);
		if (r1.source != null) {
			System.assertNotEquals(null, r2.source);
			System.assertEquals(r1.source.id, r2.source.id);
			System.assertEquals(r1.source.name, r2.source.name);
		}
		System.assertEquals(r1.readOnly, r2.readOnly);
		System.assertEquals(r1.required, r2.required);
	}

	static void compareRecipients(final List<Recipient> rs1, final List<Recipient> rs2) {
		System.assertEquals(Collection.size(rs1), Collection.size(rs2));
		if (rs1 != null) {
			Map<String, Recipient> m = new Map<String, Recipient>();
			for (Recipient r : rs1) {
				m.put(r.name, r);
			}
			for (Recipient r2 : rs2) {
				System.assertNotEquals(null, r2);
				Recipient r1 = m.get(r2.name);
				System.assertNotEquals(null, r1);
				compareRecipient(r1, r2);
			}
		}
	}

	static void compareCustomField(final CustomField cf1, final CustomField cf2) {
		System.assertNotEquals(null, cf2);
		System.assertEquals(cf1.type, cf2.type);
		System.assertEquals(cf1.name, cf2.name);
		System.assertEquals(cf1.value, cf2.value);
		System.assertEquals(cf1.items, cf2.items);
		System.assertEquals(cf1.required, cf2.required);
		System.assertEquals(cf1.show, cf2.show);

	}

	static void compareCustomFields(final List<CustomField> cfs1, final List<CustomField> cfs2) {
		System.assertEquals(Collection.size(cfs1), Collection.size(cfs2));
		if (cfs1 != null) {
			Map<String, CustomField> m = new Map<String, CustomField>();
			for (CustomField cf : cfs1) {
				m.put(cf.name, cf);
			}
			for (CustomField cf2 : cfs2) {
				System.assertNotEquals(null, cf2);
				CustomField cf1 = m.get(cf2.name);
				System.assertNotEquals(null, cf1);
				compareCustomField(cf1, cf2);
			}
		}
	}

	static void compareTab(final Tab t1, final Tab t2) {
		System.assertNotEquals(null, t2);
		System.assertEquals(t1.id, t2.id);
		System.assertEquals(t1.type, t2.type);
		System.assertEquals(t1.name, t2.name);
		System.assertEquals(t1.key, t2.key);
		System.assertEquals(t1.path, t2.path);
		System.assertEquals(t1.writeBack, t2.writeBack);
		System.assertEquals(t1.allowSenderToEdit, t2.allowSenderToEdit);
		System.assertEquals(t1.autoPlaceText, t2.autoPlaceText);
	}

	static void compareTabs(final List<Tab> ts1, final List<Tab> ts2) {
		System.assertEquals(Collection.size(ts1), Collection.size(ts2));
		if (ts1 != null) {
			Map<UUID, Tab> m = new Map<UUID, Tab>();
			for (Tab t : ts1) {
				m.put(t.id, t);
			}
			for (Tab t2 : ts2) {
				System.assertNotEquals(null, t2);
				Tab t1 = m.get(t2.id);
				System.assertNotEquals(null, t1);
				compareTab(t1, t2);
			}
		}
	}

	@IsTest
	static void test_deserialize() {
		Envelope e = new Envelope(
			UserInfo.getUserId(),
			UUID.randomUUID().toString(),
			UUID.randomUUID(),
			UserInfo.getOrganizationId(),
			new List<Document> {
				new Document(
					UserInfo.getUserId(),
					Document.TYPE_DOCUMENT,
					1,
					UUID.randomUUID().toString(),
					UUID.randomUUID().toString(),
					1111,
					Datetime.now(),
					UserInfo.getOrganizationId(),
					false,
					false,
					new List<Document> {
						new Document(
							UserInfo.getUserId(),
							Document.TYPE_DOCUMENT,
							1,
							UUID.randomUUID().toString(),
							UUID.randomUUID().toString(),
							1111,
							Datetime.now(),
							UserInfo.getOrganizationId(),
							false,
							false,
							null),
						new Document(
							UserInfo.getUserId(),
							Document.TYPE_DOCUMENT,
							2,
							UUID.randomUUID().toString(),
							UUID.randomUUID().toString(),
							2222,
							Datetime.now(),
							UserInfo.getOrganizationId(),
							true,
							true,
							null)
					}),
				new Document(
					UserInfo.getUserId(),
					Document.TYPE_TEMPLATE,
					2,
					UUID.randomUUID().toString(),
					UUID.randomUUID().toString(),
					null,
					Datetime.now(),
					UserInfo.getOrganizationId(),
					false,
					false,
					null)
			},
			new List<Recipient> {
				new Recipient(
					UserInfo.getUserId(),
					UUID.randomUUID().toString(),
					Recipient.TYPE_SIGNER,
					1,
					1,
					new Recipient.Role(
						'Signer 1',
						1),
					UUID.randomUUID().toString(),
					UUID.randomUUID() + '@unit.test',
					new SigningGroup(
						1111,
						'SG 1'),
					UUID.randomUUID().toString(),
					new Recipient.Authentication(
						'1234',
						true,
						new List<String> {
							'111111111', '22222222'
						}),
					UUID.randomUUID().toString(),
					new Recipient.EmailSettings(
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString()),
					UUID.randomUUID().toString(),
					UUID.randomUUID().toString(),
					false,
					new List<Tab> {
						new Tab(
							UUID.randomUUID(),
							Tab.TYPE_INITIAL_HERE,
							UUID.randomUUID().toString(),
							UUID.randomUUID().toString(),
							UUID.randomUUID().toString(),
							false,
							false,
							UUID.randomUUID().toString()),
						new Tab(
							UUID.randomUUID(),
							Tab.TYPE_TEXT,
							UUID.randomUUID().toString(),
							UUID.randomUUID().toString(),
							UUID.randomUUID().toString(),
							true,
							true,
							UUID.randomUUID().toString())
					},
					Entity.resolve(UserInfo.getOrganizationId()),
					false,
					false),
				new Recipient(
					UserInfo.getUserId(),
					UUID.randomUUID().toString(),
					Recipient.TYPE_SIGNER,
					1,
					1,
					new Recipient.Role(
						'Signer 1',
						1),
					UUID.randomUUID().toString(),
					UUID.randomUUID() + '@unit.test',
					new SigningGroup(
						1111,
						'SG 1'),
					UUID.randomUUID().toString(),
					new Recipient.Authentication(
						'1234',
						true,
						new List<String> {
							'111111111', '22222222'
						}),
					UUID.randomUUID().toString(),
					new Recipient.EmailSettings(
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString()),
					UUID.randomUUID().toString(),
					UUID.randomUUID().toString(),
					false,
					new List<Tab> {
						new Tab(
							UUID.randomUUID(),
							Tab.TYPE_INITIAL_HERE,
							UUID.randomUUID().toString(),
							UUID.randomUUID().toString(),
							UUID.randomUUID().toString(),
							false,
							false,
							UUID.randomUUID().toString()),
						new Tab(
							UUID.randomUUID(),
							Tab.TYPE_TEXT,
							UUID.randomUUID().toString(),
							UUID.randomUUID().toString(),
							UUID.randomUUID().toString(),
							true,
							true,
							UUID.randomUUID().toString())
					},
					Entity.resolve(UserInfo.getOrganizationId()),
					true,
					true)
			},
			new List<CustomField> {
				CustomField.newListField(
					'cf1',
					'v1',
					new List<String> { 'v1', 'v2', 'v3' },
					false,
					false),
				CustomField.newTextField(
					'cf2',
					'v2',
					true,
					true)
			},
			new Notifications(
				false,
				1,
				2,
				true,
				3,
				4),
			UUID.randomUUID().toString(),
			UUID.randomUUID().toString(),
			new Envelope.Permissions(
				true,
				false,
				true,
				false,
				true,
				false),
			new Envelope.Options(
				false,
				new Envelope.DocumentWriteBack(
					UserInfo.getUserId(),
					'NamePDF',
					false,
					true),
				new Map<String, Map<String, Object>> {
					's1' => new Map<String, Object> {
						'n1' => true,
						'n2' => 3.99,
						'n3' => StringUtils.formatDatetime(Datetime.now()),
						'n4' => 'v4'
					},
					's2' => new Map<String, Object> {
						'n5' => 'v5'
					}
				},
				new Map<String, Map<String, Object>> {
					's3' => new Map<String, Object> {
						'n6' => 'v6'
					}
				}),
			new Entity(
				UserInfo.getProfileId(),
				UUID.randomUUID().toString(),
				null),
			Datetime.now());
		String envelopeJson = JSON.serialize(e);

		Test.startTest();
		Envelope result = EnvelopeParser.deserialize(envelopeJson);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(e.id, result.id);
		System.assertEquals(e.name, result.name);
		System.assertEquals(e.docuSignId, result.docuSignId);
		System.assertEquals(e.envelopeConfigurationId, result.envelopeConfigurationId);
		compareDocuments(e.documents, result.documents);
		compareRecipients(e.recipients, result.recipients);
		compareCustomFields(e.customFields, result.customFields);
		System.assertNotEquals(null, result.notifications);
		System.assertEquals(e.notifications.remind, result.notifications.remind);
		System.assertEquals(e.notifications.remindAfterDays, result.notifications.remindAfterDays);
		System.assertEquals(e.notifications.remindFrequencyDays, result.notifications.remindFrequencyDays);
		System.assertEquals(e.notifications.expires, result.notifications.expires);
		System.assertEquals(e.notifications.expireAfterDays, result.notifications.expireAfterDays);
		System.assertEquals(e.notifications.expireWarnDays, result.notifications.expireWarnDays);
		System.assertEquals(e.emailSubject, result.emailSubject);
		System.assertEquals(e.emailMessage, result.emailMessage);
		System.assertNotEquals(null, result.senderPermissions);
		System.assertEquals(e.senderPermissions.editDocuments, result.senderPermissions.editDocuments);
		System.assertEquals(e.senderPermissions.editRecipients, result.senderPermissions.editRecipients);
		System.assertEquals(e.senderPermissions.editEmailSubject, result.senderPermissions.editEmailSubject);
		System.assertEquals(e.senderPermissions.editEmailMessage, result.senderPermissions.editEmailMessage);
		System.assertEquals(e.senderPermissions.editNotifications, result.senderPermissions.editNotifications);
		System.assertEquals(e.senderPermissions.editTags, result.senderPermissions.editTags);
		System.assertNotEquals(null, result.options);
		System.assertEquals(e.options.includeDefaultAutoPlaceTags, result.options.includeDefaultAutoPlaceTags);
		System.assertNotEquals(null, result.options.documentWriteBack);
		System.assertEquals(e.options.documentWriteBack.linkedEntityId, result.options.documentWriteBack.linkedEntityId);
		System.assertEquals(e.options.documentWriteBack.nameFormat, result.options.documentWriteBack.nameFormat);
		System.assertEquals(e.options.documentWriteBack.combineDocuments, result.options.documentWriteBack.combineDocuments);
		System.assertEquals(e.options.documentWriteBack.includeCertificateOfCompletion, result.options.documentWriteBack.includeCertificateOfCompletion);
		System.assertEquals(e.options.envelopeEventUpdates, result.options.envelopeEventUpdates);
		System.assertEquals(e.options.recipientEventUpdates, result.options.recipientEventUpdates);
		System.assertNotEquals(null, result.source);
		System.assertEquals(e.source.id, result.source.id);
		System.assertEquals(e.source.name, result.source.name);
		System.assertEquals(e.sent, result.sent);
	}
}
