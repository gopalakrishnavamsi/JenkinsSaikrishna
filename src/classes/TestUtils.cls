@IsTest
public class TestUtils {

	public static final String BASE_Url = 'https://unit.test.docusign.net/';
	public static final UUID ID1 = UUID.fromString('11111111-1111-1111-1111-111111111111');
	public static final UUID ID2 = UUID.fromString('22222222-2222-2222-2222-222222222222');
	public static final UUID ID3 = UUID.fromString('33333333-3333-3333-3333-333333333333');
	public static final UUID ID4 = UUID.fromString('44444444-4444-4444-4444-444444444444');
	public static final UUID ID5 = UUID.fromString('55555555-5555-5555-5555-555555555555');

	private static User administrator = null;

	private static User getAdministrator() {
		if (administrator == null) {
			administrator = createUser('System Administrator');
		}
		return administrator;
	}

	public static User createDocuSignAdministrator() {
		return createDocuSignAdministrator(UUID.randomUUID().toString(), null);
	}

	public static User createDocuSignAdministrator(final String dsUsername) {
		return createDocuSignAdministrator(dsUsername, null);
	}

	public static User createDocuSignAdministrator(final String dsUsername, final String dsPassword) {
		User u = createUser(UserInfo.getProfileId(), UUID.randomUUID().toString() + '@unit.test', dsUsername, true);
		if (String.isNotBlank(dsUsername)) {
			UserSettings__c us = UserSettings__c.getInstance(u.Id);
			us.Username__c = dsUsername;
			us.Password__c = dsPassword;
			upsert us;
		}
		System.runAs(getAdministrator()) {
			Permissions.assignDocuSignAdministratorPermissionSet(new Set<Id> { u.Id });
		}
		return u;
	}

	public static User createDocuSignUser() {
		return createDocusignUser(UUID.randomUUID().toString(), null);
	}

	public static User createDocuSignUser(final String dsUsername) {
		return createDocuSignUser(dsUsername, null);
	}

	public static User createDocuSignUser(final String dsUsername, final String dsPassword) {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
		User u = createUser(p.Id, UUID.randomUUID().toString() + '@unit.test', dsUsername, false);
		if (String.isNotBlank(dsUsername)) {
			UserSettings__c us = UserSettings__c.getInstance(u.Id);
			us.Username__c = dsUsername;
			us.Password__c = dsPassword;
			upsert us;
		}
		System.runAs(getAdministrator()) {
			Permissions.assignDocuSignUserPermissionSet(new Set<Id> { u.Id });
		}
		return u;
	}

	public static User createAdministrator() {
		return createUser('System Administrator');
	}

	public static User createRestrictedUser() {
		return createUser('Chatter Free User');
	}

	public static User createUser() {
		return createUser('Standard User');
	}

	public static User createUser(final String profileName) {
		return createUser([SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1].Id,
			UUID.randomUUID().toString() + '@unit.test', null, false);
	}

	public static User createUser(final Id profileId, final String email, final String dsUsername,
		final Boolean canManageAccount) {

		User u = new User(
			Email = email,
			Phone = '5555555555',
			FirstName = 'UNIT',
			LastName = 'TEST',
			Username = email,
			Alias = 'test',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'ISO-8859-1',
			ProfileId = profileId,
			LanguageLocaleKey = 'en_US',
			Username__c = dsUsername,
			CanManageAccount__c = canManageAccount);
		insert u;
		return u;
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

	public static Envelope__c createEnvelope(final Id sourceId, final UUID docuSignId) {
		Envelope__c e = new Envelope__c(
			SourceId__c = sourceId,
			DocuSignId__c = String.valueOf(docuSignId),
			EmailSubject__c = 'Subject',
			EmailMessage__c = 'Message',
			Sent__c = docuSignId == null ? null : Datetime.now());
		insert e;
		return e;
	}

	public static ContentVersion createContentVersion() {
		UUID id = UUID.randomUUID();
		ContentVersion cv = new ContentVersion(
			Title = id.toString(),
			PathOnClient = id.toString() + '.pdf',
			VersionData = Blob.valueOf(UUID.randomUUID().toString()));
		insert cv;
		return [
			SELECT ContentDocumentId, Title, PathOnClient, FileExtension, VersionData, ContentSize, LastModifiedDate
			FROM ContentVersion
			WHERE Id = :cv.Id
			LIMIT 1
		];
	}

	public static ContentVersion createContentVersion(final Id sourceId) {
		ContentVersion cv = createContentVersion();
		createContentDocumentLink(sourceId, cv);
		return cv;
	}

	public static Document__c createEnvelopeDocument(final Id envelopeId) {
		return createEnvelopeDocument(envelopeId, createContentVersion(), 1);
	}

	public static Document__c createEnvelopeDocument(final Id envelopeId, final Integer sequence) {
		return createEnvelopeDocument(envelopeId, createContentVersion(), sequence);
	}

	public static Document__c createEnvelopeDocument(final Id envelopeId, final String type, final Id id, final String name, final Integer sequence) {
		Document__c ed = new Document__c(
			Envelope__c = envelopeId,
			Name = name,
			SourceId__c = id,
			Sequence__c = sequence,
			Size__c = 1234,
			Extension__c = 'pdf',
			Type__c = type);
		insert ed;
		return ed;
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

	public static Recipient__c createEnvelopeRecipient(final Id envelopeId, final Integer sequence) {
		Recipient__c r = new Recipient__c(
			Envelope__c = envelopeId,
			Type__c = Recipient.TYPE_SIGNER,
			Sequence__c = sequence,
			RoutingOrder__c = sequence,
			Role__c = 'rr' + sequence,
			Name = UUID.randomUUID().toString(),
			Email__c = UUID.randomUUID().toString() + '@unit.test');
		insert r;
		return r;
	}

	public static Schema.Account createAccount() {
		Schema.Account a = new Schema.Account(Name = 'UNIT TEST');
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

	public static OpportunityContactRole createOpportunityContactRole(final Id opportunityId, final Id contactId) {
		OpportunityContactRole ocr = new OpportunityContactRole(
			OpportunityId = opportunityId,
			ContactId = contactId,
			Role = UUID.randomUUID().toString());
		insert ocr;
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

	public static Contact createContact() {
		return createContact(createAccount().Id);
	}

	public static Contact createContact(final Id accountId) {
		Contact c = new Contact(
			AccountId = accountId,
			FirstName = UUID.randomUUID().toString(),
			LastName = UUID.randomUUID().toString(),
			Email = UUID.randomUUID().toString() + '@unit.test',
			Phone = '5555555555');
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

	public static UUID createAccountConfiguration() {
		final UUID accountId = UUID.randomUUID();
		return createAccountConfiguration(accountId, accountId.toString() + '@unit.test');
	}

	public static UUID createAccountConfiguration(final UUID accountId, final String username) {
		AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
		accountSettings.Environment__c = 'other';
		accountSettings.BaseUrl__c = BASE_Url;
		accountSettings.AccountId__c = String.valueOf(accountId);
		accountSettings.Username__c = username;
		accountSettings.Password__c = UUID.randomUUID().toShortString();
		accountSettings.UseSendOnBehalfOf__c = true;
		accountSettings.SetupComplete__c = true;
		accountSettings.EntityResolvers__c = Application.classNamespacePrefix + 'DefaultEntityResolver';
		accountSettings.DocumentResolvers__c = Application.classNamespacePrefix + 'DefaultDocumentResolver';
		accountSettings.RecipientResolvers__c = Application.classNamespacePrefix + 'DefaultRecipientResolver';
		accountSettings.CanUseSalesforceApi__c = true;
		insert accountSettings;

		insert EnvelopeSettings__c.getOrgDefaults();

		insert ChatterSettings__c.getOrgDefaults();

		insert new List<RoleSettings__c> {
			new RoleSettings__c(Name = 'Signer 1', Value__c = 1),
			new RoleSettings__c(Name = 'Signer 2', Value__c = 2),
			new RoleSettings__c(Name = 'Signer 3', Value__c = 3),
			new RoleSettings__c(Name = 'Signer 4', Value__c = 4)
		};

		insert new EnvelopeLocalization__c(
			Name = 'English',
			Language__c = 'en',
			EmailSubject__c = 'Please sign this document',
			EmailMessage__c = 'This email contains a document');
		return accountId;
	}

	public static Schema.Document createDocument() {
		return createDocument(UserInfo.getUserId());
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

	public static EnvelopeStatus__c createEnvelopeStatus(final Id sourceId) {
		EnvelopeStatus__c es = new EnvelopeStatus__c(
			DocuSignId__c = UUID.randomUUID().toString(),
			SourceId__c = sourceId,
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

	public static RecipientStatus__c createRecipientStatus(final Id esId, final Integer sequence) {
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

	public static RecipientStatus__c createRecipientStatus(final Id esId, final Recipient__c r) {
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
}
