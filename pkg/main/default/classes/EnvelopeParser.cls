public class EnvelopeParser {

	private static Envelope.DocumentWriteBack reifyDocumentWriteBack(final Map<String, Object> m) {
		if (Collection.isEmpty(m)) return null;

		return new Envelope.DocumentWriteBack(
			(Id)m.get('linkedEntityId'),
			(String)m.get('nameFormat'),
			(Boolean)m.get('combineDocuments') == true,
			(Boolean)m.get('includeCertificateOfCompletion') == true);
	}

	private static Map<String, Map<String, Object>> reifyUpdateMap(final Map<String, Object> updates) {
		Map<String, Map<String, Object>> result = new Map<String, Map<String, Object>>();

		if (updates == null) return result;

		for (String key : updates.keySet()) {
			result.put(key, (Map<String, Object>)updates.get(key));
		}

		return result;
	}

	private static Document reifyDocument(final Map<String, Object> m) {
		if (Collection.isEmpty(m)) return null;

		return new Document(
			(Id)m.get('id'),
			(String)m.get('type'),
			(Integer)m.get('sequence'),
			(String)m.get('name'),
			(String)m.get('extension'),
			(Integer)m.get('size'),
			StringUtils.parseDatetime((String)m.get('lastModified')),
			(String)m.get('sourceId'),
			(Boolean)m.get('readOnly') == true,
			(Boolean)m.get('required') == true,
			reifyDocuments((List<Object>)m.get('templateDocuments')));
	}

	private static List<Document> reifyDocuments(final List<Object> ls) {
		if (ls == null) return new List<Document>();

		List<Document> result = new List<Document>();
		for (Object obj : ls) {
			Document d = reifyDocument((Map<String, Object>)obj);
			if (d != null) result.add(d);
		}
		return result;
	}

	private static Recipient.Role reifyRole(final Map<String, Object> m) {
		if (Collection.isEmpty(m)) return null;

		return new Recipient.Role(
			(String)m.get('name'),
			(Integer)m.get('value'));
	}

	private static SigningGroup reifySigningGroup(final Map<String, Object> m) {
		if (Collection.isEmpty(m)) return null;

		return new SigningGroup(
			(Integer)m.get('id'),
			(String)m.get('name'));
	}

	private static List<String> reifyStringList(final List<Object> ls) {
		if (ls == null) return new List<String>();

		List<String> result = new List<String>();
		for (Object obj : ls) {
			result.add((String)obj);
		}
		return result;
	}

	private static Recipient.Authentication reifyAuthentication(final Map<String, Object> m) {
		if (Collection.isEmpty(m)) return null;

		return new Recipient.Authentication(
			(String)m.get('accessCode'),
			(Boolean)m.get('idCheckRequired') == true,
			reifyStringList((List<Object>)m.get('smsPhoneNumbers')));
	}

	private static Recipient.EmailSettings reifyEmailSettings(final Map<String, Object> m) {
		if (Collection.isEmpty(m)) return null;

		return new Recipient.EmailSettings(
			(String)m.get('language'),
			(String)m.get('languageLabel'),
			(String)m.get('subject'),
			(String)m.get('message'));
	}

	private static Tab reifyTab(final Map<String, Object> m) {
		if (Collection.isEmpty(m)) return null;

		return new Tab(
			reifyUUID((Map<String, Object>)m.get('id')),
			(String)m.get('type'),
			(String)m.get('name'),
			(String)m.get('key'),
			(String)m.get('path'),
			(Boolean)m.get('writeBack') == true,
			(Boolean)m.get('allowSenderToEdit') == true,
			(String)m.get('autoPlaceText'));
	}

	private static List<Tab> reifyTabs(final List<Object> ls) {
		if (ls == null) return new List<Tab>();

		List<Tab> result = new List<Tab>();
		for (Object obj : ls) {
			Tab t = reifyTab((Map<String, Object>)obj);
			if (t != null) result.add(t);
		}
		return result;
	}

	private static Recipient reifyRecipient(final Map<String, Object> m) {
		if (Collection.isEmpty(m)) return null;

		return new Recipient(
			(Id)m.get('id'),
			(String)m.get('envelopeRecipientId'),
			(String)m.get('type'),
			(Integer)m.get('sequence'),
			(Integer)m.get('routingOrder'),
			reifyRole((Map<String, Object>)m.get('role')),
			(String)m.get('name'),
			(String)m.get('email'),
			reifySigningGroup((Map<String, Object>)m.get('signingGroup')),
			(String)m.get('phone'),
			reifyAuthentication((Map<String, Object>)m.get('authentication')),
			(String)m.get('note'),
			reifyEmailSettings((Map<String, Object>)m.get('emailSettings')),
			(String)m.get('hostName'),
			(String)m.get('hostEmail'),
			(Boolean)m.get('signNow') == true,
			reifyTabs((List<Object>)m.get('tabs')),
			reifyEntity((Map<String, Object>)m.get('source')),
			(Boolean)m.get('readOnly') == true,
			(Boolean)m.get('required') == true);
	}

	private static List<Recipient> reifyRecipients(final List<Object> ls) {
		if (ls == null) return new List<Recipient>();

		List<Recipient> result = new List<Recipient>();
		for (Object obj : ls) {
			Recipient r = reifyRecipient((Map<String, Object>)obj);
			if (r != null) result.add(r);
		}
		return result;
	}

	private static UUID reifyUUID(final Map<String, Object> m) {
		return m == null || !m.containsKey('value') ? null : UUID.parse((String)m.get('value'));
	}

	private static CustomField reifyCustomField(final Map<String, Object> m) {
		if (Collection.isEmpty(m)) return null;

		return new CustomField(
			(String)m.get('type'),
			(String)m.get('name'),
			(String)m.get('value'),
			reifyStringList((List<Object>)m.get('items')),
			(Boolean)m.get('required') == true,
			(Boolean)m.get('show') == true);
	}

	private static List<CustomField> reifyCustomFields(final List<Object> ls) {
		if (ls == null) return new List<CustomField>();

		List<CustomField> result = new List<CustomField>();
		for (Object obj : ls) {
			CustomField cf = reifyCustomField((Map<String, Object>)obj);
			if (cf != null) result.add(cf);
		}
		return result;
	}

	private static Notifications reifyNotifications(final Map<String, Object> m) {
		if (Collection.isEmpty(m)) return null;

		return new Notifications(
			(Boolean)m.get('remind') == true,
			(Integer)m.get('remindAfterDays'),
			(Integer)m.get('remindFrequencyDays'),
			(Boolean)m.get('expires') == true,
			(Integer)m.get('expireAfterDays'),
			(Integer)m.get('expireWarnDays'));
	}

	private static Envelope.Permissions reifyPermissions(final Map<String, Object> m) {
		if (Collection.isEmpty(m)) return null;

		return new Envelope.Permissions(
			(Boolean)m.get('editDocuments') == true,
			(Boolean)m.get('editRecipients') == true,
			(Boolean)m.get('editEmailSubject') == true,
			(Boolean)m.get('editEmailMessage') == true,
			(Boolean)m.get('editNotifications') == true,
			(Boolean)m.get('editTags') == true);
	}

	private static Entity reifyEntity(final Map<String, Object> m) {
		if (Collection.isEmpty(m)) return null;

		return new Entity(
			(Id)m.get('id'),
			(String)m.get('name'),
			reifyEntity((Map<String, Object>)m.get('parent')));
	}

	public static Envelope deserialize(final String envelopeJson) {
		if (String.isBlank(envelopeJson)) return null;

		Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(envelopeJson);
		if (Collection.isEmpty(m)) return null;

		return new Envelope(
			(Id)m.get('id'),
			(String)m.get('name'),
			reifyUUID((Map<String, Object>)m.get('docuSignId')),
			(Id)m.get('envelopeConfigurationId'),
			reifyDocuments((List<Object>)m.get('documents')),
			reifyRecipients((List<Object>)m.get('recipients')),
			reifyCustomFields((List<Object>)m.get('customFields')),
			reifyNotifications((Map<String, Object>)m.get('notifications')),
			(String)m.get('emailSubject'),
			(String)m.get('emailMessage'),
			reifyPermissions((Map<String, Object>)m.get('senderPermissions')),
			reifyOptions((Map<String, Object>)m.get('options')),
			reifyEntity((Map<String, Object>)m.get('source')),
			StringUtils.parseDatetime((String)m.get('sent')));
	}

	public static Envelope.Options deserializeOptions(final String optionsJson) {
		Envelope.Options result = null;

		if (String.isBlank(optionsJson)) return result;

		Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(optionsJson);
		if (m != null) {
			result = new Envelope.Options(
				StringUtils.parseBoolean(String.valueOf(m.get('includeDefaultAutoPlaceTags'))),
				reifyDocumentWriteBack((Map<String, Object>)m.get('documentWriteBack')),
				reifyUpdateMap((Map<String, Object>)m.get('envelopeEventUpdates')),
				reifyUpdateMap((Map<String, Object>)m.get('recipientEventUpdates')));
		}

		return result;
	}

	public static Envelope.Options reifyOptions(final Map<String, Object> options) {
		Envelope.Options result = null;

		if (options == null) return result;

		result = new Envelope.Options(
			StringUtils.parseBoolean(String.valueOf(options.get('includeDefaultAutoPlaceTags'))),
			reifyDocumentWriteBack((Map<String, Object>)options.get('documentWriteBack')),
			reifyUpdateMap((Map<String, Object>)options.get('envelopeEventUpdates')),
			reifyUpdateMap((Map<String, Object>)options.get('recipientEventUpdates')));

		return result;
	}
}
