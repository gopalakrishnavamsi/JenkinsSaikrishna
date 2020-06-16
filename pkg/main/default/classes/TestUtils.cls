/**
 * Utility methods to support unit testing.
 */
@IsTest
global class TestUtils {

	/**
	 * Sets an HTTP callout mock for a unit test. This method must be called from external code requiring use of the
	 * DocuSign REST API mocks instead of calling <code>Test.setMock</code> directly.
	 *
	 * @param mock An instance of a class implementing the <code>HttpCalloutMock</code> interface.
	 *
	 * @return The HTTP callout mock.
	 */
	global static HttpCalloutMock setMock(final HttpCalloutMock mock) {
		Test.setMock(HttpCalloutMock.class, mock);
		return mock;
	}

	/**
	 * Sets an SOAP callout mock for a unit test. This method must be called from external code requiring use of the
	 * DocuSign SOAP API mocks instead of calling <code>Test.setMock</code> directly.
	 *
	 * @param mock An instance of a class implementing the <code>WebServiceMock</code> interface.
	 *
	 * @return The SOAP callout mock.
	 */
	global static WebServiceMock setMock(final WebServiceMock mock) {
		Test.setMock(WebServiceMock.class, mock);
		return mock;
	}

	public static Integer randomInteger(final Integer maxValue) {
		return Integer.valueOf(Math.random() * maxValue);
	}

	public static String randomString(final Integer length) {
		final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
		String result = '';
		while (result.length() < length) {
			Integer i = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
			result += chars.substring(i, i + 1);
		}
		return result;
	}

	public static Envelope__c createEnvelope() {
		return createEnvelope(null, UUID.randomUUID());
	}

	public static Envelope__c createEnvelope(final Id sourceId) {
		return createEnvelope(sourceId, UUID.randomUUID());
	}

	public static Envelope__c createEnvelope(final UUID docuSignId) {
		return createEnvelope(null, docuSignId);
	}

	public static Envelope__c createEnvelope(
		final Id sourceId,
		final UUID docuSignId) {

		return createEnvelope(sourceId, docuSignId, null);
	}

	public static Envelope__c createEnvelope(
		final Id sourceId,
		final UUID docuSignId,
		final Envelope.Options options) {

		Envelope__c e = new Envelope__c(
			SourceId__c = sourceId,
			DocuSignId__c = String.valueOf(docuSignId),
			EmailSubject__c = 'Subject',
			EmailMessage__c = 'Message',
			Sent__c = docuSignId == null ? null : Datetime.now(),
			Options__c = options == null ? null : JSON.serialize(options));
		insert e;
		return e;
	}

	public static ContentVersion createContentVersion() {
		return createContentVersion(
			UUID.randomUUID().toString(),
			'pdf'
		);
	}

	public static ContentVersion createContentVersion(
		final String title,
		final String fileExtension) {

		ContentVersion cv = new ContentVersion(
			Title = title,
			PathOnClient = title + '.' + fileExtension,
			VersionData = Blob.valueOf(UUID.randomUUID().toString()),
			IsMajorVersion = false);
		insert cv;
		return [
			SELECT ContentDocumentId, Title, PathOnClient, FileExtension, VersionData, ContentSize, LastModifiedDate
			FROM ContentVersion
			WHERE Id = :cv.Id
			LIMIT 1
		];
	}

	public static ContentVersion createContentVersion(final Id sourceId) {
		return createContentVersion(
			sourceId,
			UUID.randomUUID().toString(),
			'pdf');
	}

	public static ContentVersion createContentVersion(
		final Id sourceId,
		final String title,
		final String fileExtension) {

		ContentVersion cv = createContentVersion(title, fileExtension);
		createContentDocumentLink(sourceId, cv);
		return cv;
	}

	public static Document__c createEnvelopeDocument(final Id envelopeId) {
		return createEnvelopeDocument(envelopeId, createContentVersion(), 1);
	}

	public static Document__c createEnvelopeDocument(final Id envelopeId, final Integer sequence) {
		return createEnvelopeDocument(envelopeId, createContentVersion(), sequence);
	}

	public static Document__c createEnvelopeDocument(final Id envelopeId, final ContentVersion file, final Integer sequence) {
		return createEnvelopeDocument(envelopeId, file, Document.TYPE_FILE, sequence);
	}

	public static Document__c createEnvelopeDocument(final Id envelopeId, final ContentVersion file, final String type, final Integer sequence) {
		Document__c ed = new Document__c(
			Envelope__c = envelopeId,
			Name = file.Title,
			SourceId__c = file.Id,
			Sequence__c = sequence,
			Size__c = file.ContentSize,
			Extension__c = file.FileExtension,
			Type__c = type);
		insert ed;
		return ed;
	}

	public static Document__c createEnvelopeDocument(final Id envelopeId, final Schema.Document doc, final Integer sequence) {
		Document__c ed = new Document__c(
			Envelope__c = envelopeId,
			Name = doc.Name,
			SourceId__c = doc.Id,
			Sequence__c = sequence,
			Size__c = 1234,
			Extension__c = 'pdf',
			Type__c = Document.TYPE_DOCUMENT);
		insert ed;
		return ed;
	}

	public static Recipient__c createEnvelopeRecipient(final Id envelopeId) {
		return createEnvelopeRecipient(envelopeId, 1);
	}

	public static Recipient__c createEnvelopeRecipient(
		final Id envelopeId,
		final Integer sequence) {

		return createEnvelopeRecipient(envelopeId, sequence, null);
	}

	public static Recipient__c createEnvelopeRecipient(
		final Id envelopeId,
		final Integer sequence,
		final SObject source) {

		Recipient__c r = new Recipient__c(
			Envelope__c = envelopeId,
			Type__c = Recipient.TYPE_SIGNER,
			Sequence__c = sequence,
			RoutingOrder__c = sequence,
			Role__c = 'rr' + sequence,
			Name = source != null && source.isSet('Name')
				? (String)source.get('Name') : UUID.randomUUID().toString(),
			Email__c = source != null && source.isSet('Email')
				? (String)source.get('Email') : UUID.randomUUID().toString() + '@unit.test',
			SourceId__c = source != null ? source.Id : null);
		insert r;
		return r;
	}

	public static Schema.Account createAccount() {
		Schema.Account a = new Schema.Account(Name = 'UNIT TEST');
		insert a;
		return a;
	}

	public static Schema.Account createAccountWithName(final String name) {
		String accountName = name;
		if (accountName == null) {
			accountName = 'UNIT TEST';
		}
		Schema.Account a = new Schema.Account(Name = accountName);
		insert a;
		return a;
	}

	public static Opportunity createOpportunity() {
		return createOpportunity(createAccount().Id);
	}

	public static Opportunity createOpportunity(final Id accountId) {
		Opportunity o = new Opportunity(
			AccountId = accountId,
			Name = 'UNIT TEST',
			CloseDate = Date.today(),
			StageName = 'Negotiation/Review');
		insert o;
		return o;
	}

	public static OpportunityContactRole createOpportunityContactRole(
		final Id opportunityId,
		final Id contactId) {

		return createOpportunityContactRole(
			opportunityId,
			contactId,
			UUID.randomUUID().toString());
	}

	public static OpportunityContactRole createOpportunityContactRole(
		final Id opportunityId,
		final Id contactId,
		final String role) {

		OpportunityContactRole ocr = new OpportunityContactRole(
			OpportunityId = opportunityId,
			ContactId = contactId,
			Role = role);
		insert ocr;
		ocr = [
			SELECT Id, ContactId, OpportunityId, Contact.Name, Contact.FirstName, Contact.LastName, Contact.Email,
				Contact.Phone, Contact.MobilePhone, Role
			FROM OpportunityContactRole
			WHERE Id = :ocr.Id
			LIMIT 1
		];
		return ocr;
	}

	public static Case createCase() {
		Schema.Account a = createAccount();
		return createCase(a.Id, createContact(a.Id).Id);
	}

	public static Case createCase(final Id accountId, final Id contactId) {
		Case c = new Case(AccountId = accountId, ContactId = contactId);
		insert c;
		c = [SELECT Id, CaseNumber, Account.Id, Account.Name, Contact.Id, Contact.Name FROM Case WHERE Id = :c.Id];
		return c;
	}

	public static CaseContactRole createCaseContactRole(
		final Id caseId,
		final Id contactId) {

		CaseContactRole ccr = new CaseContactRole(
			CasesId = caseId,
			ContactId = contactId,
			Role = UUID.randomUUID().toString());
		insert ccr;
		return ccr;
	}

	public static Contact createContact() {
		return createContact(createAccount().Id);
	}

	public static Contact createContact(final Id accountId) {
		return createContact(
			accountId,
			UUID.randomUUID().toString(),
			UUID.randomUUID().toString(),
			UUID.randomUUID() + '@unit.test',
			String.valueOf(randomInteger(10000000)));
	}

	public static Contact createContact(
		final Id accountId,
		final String firstName,
		final String lastName,
		final String email,
		final String phone) {

		Contact c = new Contact(
			AccountId = accountId,
			FirstName = firstName,
			LastName = lastName,
			Email = email,
			Phone = phone);
		insert c;
		return [SELECT AccountId, Name, FirstName, LastName, Email, Phone FROM Contact WHERE Id = :c.Id LIMIT 1];
	}

	public static Lead createLead() {
		Lead l = new Lead(
			FirstName = UUID.randomUUID().toString(),
			LastName = UUID.randomUUID().toString(),
			Company = 'Acme Corp.',
			Email = UUID.randomUUID().toString() + '@unit.test',
			Phone = '5555555555');
		insert l;
		return [SELECT Company, Name, FirstName, LastName, Email, Phone FROM Lead WHERE Id = :l.Id LIMIT 1];
	}

	public static Schema.Document createDocument() {
		return createDocument(UserInfo.getUserId());
	}

	public static SObject createAgreementConfiguration(final Id sourceObjectId, final String folderId, final String tempFolderId) {

		AgreementConfiguration__c configuration = new AgreementConfiguration__c();
		configuration.FolderId__c = folderId;
		configuration.TempFolderId__c = tempFolderId;
		configuration.SourceObject__c = sourceObjectId;
		insert configuration;
		return configuration;
	}

	public static Schema.Document createDocument(final Id folderId) {
		Schema.Document d = new Schema.Document(
			Name = UUID.randomUUID().toString() + '.pdf',
			Body = Blob.valueOf(UUID.randomUUID().toString()),
			FolderId = folderId);
		insert d;
		return [SELECT Name, Type, Body, BodyLength, FolderId, LastModifiedDate FROM Document WHERE Id = :d.Id LIMIT 1];
	}

	public static ContentWorkspace createContentWorkspace() {
		ContentWorkspace cw = new ContentWorkspace(Name = UUID.randomUUID().toString());
		insert cw;
		return cw;
	}

	public static ContentWorkspace getFirstAvailableContentWorkspace() {
		List<ContentWorkspace> cws = [SELECT Id, Name FROM ContentWorkspace ORDER BY Name LIMIT 1];
		if (Collection.isNotEmpty(cws)) {
			return cws[0];
		}
		return null;
	}

	public static ContentWorkspaceDoc createContentWorkspaceDoc(final Id contentWorkspaceId, final Id contentDocumentId) {
		ContentWorkspaceDoc cwd = new ContentWorkspaceDoc(
			ContentWorkspaceId = contentWorkspaceId,
			ContentDocumentId = contentDocumentId);
		insert cwd;
		return cwd;
	}

	public static ContentDocumentLink createContentDocumentLink(final Id linkedEntityId) {
		return createContentDocumentLink(linkedEntityId, createContentVersion());
	}

	public static ContentDocumentLink createContentDocumentLink(final Id linkedEntityId, final ContentVersion contentVersion) {
		ContentDocumentLink cdl = new ContentDocumentLink(
			ContentDocumentId = contentVersion.ContentDocumentId,
			LinkedEntityId = linkedEntityId,
			ShareType = 'I');
		insert cdl;
		return cdl;
	}

	public static EnvelopeLocalization__c createEnvelopeLocalization(final String language) {
		return createEnvelopeLocalization(new Recipient.EmailSettings(language, Localization.getLabel(language),
			language + ' subject', language + ' message'));
	}

	public static EnvelopeLocalization__c createEnvelopeLocalization(final Recipient.EmailSettings loc) {
		EnvelopeLocalization__c el = new EnvelopeLocalization__c(
			Name = loc.languageLabel,
			Language__c = loc.language,
			EmailSubject__c = loc.subject,
			EmailMessage__c = loc.message);
		insert el;
		Localization.isEmailEnabled = true;
		return el;
	}

	public static EnvelopeStatus__c createEnvelopeStatus() {
		return createEnvelopeStatus(UUID.randomUUID());
	}

	public static EnvelopeStatus__c createEnvelopeStatus(final UUID dseId) {
		EnvelopeStatus__c es = new EnvelopeStatus__c(
			DocuSignId__c = String.valueOf(dseId),
			Status__c = Envelope.STATUS_CREATED,
			EmailSubject__c = 'Unit test subject',
			LastStatusUpdate__c = Datetime.now());
		insert es;
		return es;
	}

	public static EnvelopeStatus__c createEnvelopeStatus(final Envelope__c e) {
		EnvelopeStatus__c es = new EnvelopeStatus__c(
			SourceId__c = e.SourceId__c,
			DocuSignId__c = e.DocuSignId__c,
			Status__c = e.Sent__c == null ? Envelope.STATUS_CREATED : Envelope.STATUS_SENT,
			Sent__c = e.Sent__c,
			EmailSubject__c = e.EmailSubject__c,
			LastStatusUpdate__c = Datetime.now());
		insert es;
		return es;
	}

	public static RecipientStatus__c createRecipientStatus(
		final Id esId,
		final Integer sequence) {

		RecipientStatus__c rs = new RecipientStatus__c(
			EnvelopeStatus__c = esId,
			SourceId__c = UserInfo.getUserId(),
			Type__c = Recipient.TYPE_SIGNER,
			Sequence__c = sequence,
			Status__c = Recipient.STATUS_CREATED,
			Name = 'Unit Test',
			Email__c = 'r@unit.test',
			RoutingOrder__c = sequence,
			LastStatusUpdate__c = Datetime.now());
		insert rs;
		return rs;
	}

	public static RecipientStatus__c createRecipientStatus(
		final Id esId,
		final Recipient__c r) {

		RecipientStatus__c rs = new RecipientStatus__c(
			EnvelopeStatus__c = esId,
			SourceId__c = r.SourceId__c,
			Type__c = r.Type__c,
			Sequence__c = r.Sequence__c,
			Status__c = Recipient.STATUS_CREATED,
			Name = r.Name,
			Email__c = r.Email__c,
			RoutingOrder__c = r.RoutingOrder__c,
			LastStatusUpdate__c = Datetime.now());
		insert rs;
		return rs;
	}

	public static String generateKey() {
		String key = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.EncryptionKey__c = key;
		upsert s;
		return key;
	}

	private static String generateNonce() {
		String nonce = UUID.randomUUID().toShortString();
		UserSettings__c s = UserSettings__c.getInstance();
		s.Nonce__c = nonce;
		upsert s;
		return nonce;
	}

	private static String origin;

	public static String getOrigin() {
		if (origin == null) {
			origin = 'https://'
				+ Url.getOrgDomainUrl().getHost().substringBefore('.')
				+ '--' + Application.namespace
				+ '.visualforce.com';
		}
		return origin;
	}

	public static String generateState(final Boolean setup) {
		generateKey();
		return SecureUtils.encrypt(generateNonce()
			+ '|' + (setup ? LoginInformation.TYPE_SETUP : LoginInformation.TYPE_USER)
			+ '|' + getOrigin()
			+ '|Other|https://unit.test.docusign.net/');
	}

	public static GenTemplate__c createGenTemplate(final SObjectType sourceType) {
		GenTemplate__c t = new GenTemplate__c(
			Name = randomString(10),
			HasPreviewedDocuments__c = false,
			IsSample__c = false,
			ObjectMappings__c = '{"version":2,"name":"Opportunity","label":"Opportunity","fieldMappings":[{"type":"ROOT","path":[],"key":"Opportunity","fields":[{"type":"REFERENCE","scale":0,"relationship":"Owner","relatesTo":"User","parentIdField":"OwnerId","name":"Owner","matchType":null,"label":"Owner ID","isConditional":false,"isChildRelation":false,"format":null,"conditionalValue":null}],"depth":1},{"type":"REFERENCE","path":["Owner"],"key":"Owner","fields":[{"type":"EMAIL","scale":0,"relationship":null,"relatesTo":"","parentIdField":"Email","name":"Email","matchType":null,"label":"Email","isConditional":false,"isChildRelation":false,"format":null,"conditionalValue":null}],"depth":2}]}',
			SignerMappings__c = '[{"fieldMappings":[{"apiName":"s"}]}]',
			SourceObject__c = String.valueOf(sourceType),
			StepsCompleted__c = 1,
			UseAllTemplates__c = true,
			UseCurrentRecord__c = true);
		insert t;
		return t;
	}

	public static ContentVersion createGenFile(final Id templateId) {
		String title = randomString(10);
		ContentVersion cv = new ContentVersion(
			Title = title,
			PathOnClient = title + '.docx',
			VersionData = Blob.valueOf(UUID.randomUUID().toString()),
			IsMajorVersion = false,
			GeneratedFileFormat__c = 'Word',
			GeneratedFileName__c = title,
			GeneratedFileSuffix__c = 'name',
			Rule__c = '{"name":"Test Rule","ruleType":"any","conditions":[{"fieldName":"Name","fieldType":"STRING","matchType":"equals","matchValue":"UNIT TEST"},{"fieldName":"Name","fieldType":"STRING","matchType":"equals","matchValue":"TEST UNIT"},{"fieldName":"AnnualRevenue","fieldType":"CURRENCY","matchType":"notEquals","matchValue":""}]}');
		insert cv;
		cv = [
			SELECT Id, ContentDocumentId, Title, ContentSize, FileExtension,
				GeneratedFileFormat__c, GeneratedFileName__c, GeneratedFileSuffix__c, Rule__c
			FROM ContentVersion
			WHERE Id = :cv.Id
			LIMIT 1
		];
		createContentDocumentLink(templateId, cv);
		return cv;
	}

	// This is a structurally-valid 2048-bit RSA private key for testing purposes. This is not tied to any actual account.
	public static final String TEST_RSA_PRIVATE_KEY_BASE64 =
		'MIIEpAIBAAKCAQEAyfhkfcR7atmNMmcqFFYcxYoXjo387ZKprD7t7ucdyZ2UFK0zXmY1x9PhBJTaB1VsAjvDHusYY6YjWX4ZcEJPOpNpYleJdOPDNUKLJJD62jzQ+vDZhjmdFR8jUWmuFR/pDR49X56c9maMD0r2VHsuHN8eUKUvtqgiflJjaUXuN7UxHFtloEQML41jOT56ShDy2JkKqc6KLj6jbLKVJV7/OoZsOf1e5wp26pekERM6mO+cws'
			+ 'XtLbd3+kBRqiuvRWlIgJvu0RYyf3kI3pMROozcqlODK8XmFyYmQDQstt5uToHwAKMbICxb4c7Y+GGBOkNrP6yPsbMMIqBY64ocLnO7cQIDAQABAoIBAA+FEtPHQWSYiw0QeF9Prq5PSjgeGQ14c6lUvJvbDqLrhPGBzay3VfKhCW18srRVkBMr3HaHwjwGDDlYQ0QpFEWABl0UNO/SgLGbB24r5drXSYe+8jgqPTPeTKx43nOpHBNx+21Zlt4o'
			+ 'SyLxs7QSMxzs2DuCNgRnLx9d3V29jeyh0MO0yvHaT0qge85kJKcIa7HF1wlh7pHidyczxy2nWqtX2zZl36HcUUveH0JOonzrJfvAQID3Z7XF9SibivX4kmJNDUjm3mM8dnl8aP+zT1nbNBVYOqnRTIPwiLhsHXAHXpokfWXALDFkuMKSSeE8FyzYExQci8CLlJTbE6EXdwECgYEA7pilm+UeUxDDjQEMwltrOocP9QZfl5dxFhNDDypSIUMwC2'
			+ '01VukrNNTd8tOLH3xwK/pLHEHz7h8dFbU0mGspP53jPjrPi4kzkFsXVexeCnVF2lX4kAP45E36XphsPzUwDbvF4qoTaXy7JsctJsEo/NdlqJZZEfsO9uBQyG8nVukCgYEA2LPSUtktZEgTujdiKTt0K7OrNC2nEh2P43qiPIDrgOeNWi23qUAphMUH0Vh6pTL8JC5w1vWHURC7yl1xuQmms4q0pOXFxfckpY4dDdqsH9KCRpiVAwKBUfJgM70B'
			+ 'cPjyys75tgJRyDmEPBcFxDtkbLuuz7a4IO+vN1I0oDFqe0kCgYEA2GkGFT+c4LTc2eEw5Hys5roopBLy03meLeqssW2ubtMVGdglQD5fXR0SbzSnBJkG2Sy9wdSkXsBDzjO8j97q2/PmcMRBCYwZg/7LTLkGly/FewLtYBrqPpHn3LMdw7sHaf19wFiJIO3shoC0GGmtNqBcaaxs/50a9puBSjtfkDkCgYEAycUdF1Dpx86ot6Frv5KBB1PiG9'
			+ 'JKFj76Q8dimc07+ikfXxDkSi3YuquuLMkiYQEI7jNjk3LHjL506+Z3xd9rnQ6QRl0++aW1NIUPHmA2Fecur8bQMB48BO4Vjvb0CZlyj02KCmM8fJ65Ni4Fi4H1bpyOFw89gEVLssnTADkiuSkCgYB17u98imy/K/9hjIHE28n7ltacCpF47o2GXAyeZOD/EW68/l5HwyL8kgoFrFpfdp4ihyejVjcTsNw84SewDOstiAtrth2qQCYCBZJ97iIr'
			+ 'XaJnU+zXzC1II4ZNpaUQjJZJ2wDppQnz4RPIueCBM5RwN8MvXBiZGGO7/UmcpcUkGA==';
	public static final Blob TEST_RSA_PRIVATE_KEY = EncodingUtil.base64Decode(TEST_RSA_PRIVATE_KEY_BASE64);

	public static EnvelopeConfiguration__c createEnvelopeConfiguration() {
		return createEnvelopeConfiguration(UUID.randomUUID().toString(), 'Account');
	}

	public static EnvelopeConfiguration__c createEnvelopeConfiguration(
		final String name,
		final String sourceObject) {

		EnvelopeConfiguration__c result = new EnvelopeConfiguration__c(
			Name = name,
			SourceObject__c = sourceObject,
			DocuSignId__c = String.valueOf(UUID.randomUUID()));
		insert result;
		return result;
	}

	public static EnvelopeConfigurationDocument__c createEnvelopeConfigurationDocument(
		final String name,
		final Id envelopeConfiguration,
		final String sourceId,
		final String type) {
		EnvelopeConfigurationDocument__c result = new EnvelopeConfigurationDocument__c(
			Name__c = name,
			EnvelopeConfiguration__c = envelopeConfiguration,
			SourceId__c = sourceId,
			Type__c = type);
		insert result;
		return result;
	}
}
