public with sharing class RecipientService {

	@TestVisible
	private static final RecipientService.Database DB = new RecipientService.Database();
	private static final LoggerService LOG = LoggerService.getInstance();
	private static List<Recipient.Role> DEFAULT_ROLES = null;
	private static final List<RecipientResolver> RECIPIENT_RESOLVERS = new List<RecipientResolver>();

	static {
		String rs = AccountSettings__c.getOrgDefaults().RecipientResolvers__c;
		if (String.isNotBlank(rs)) {
			for (String r : rs.split(',')) {
				try {
					RECIPIENT_RESOLVERS.add((RecipientResolver)Type.forName(r.trim()).newInstance());
				} catch (Exception ex) {
					LoggerService.getInstance().exception(ex, 'Invalid recipient resolver: ' + r.trim());
					throw new DocuSignException(String.format(Label.InvalidRecipientResolver_1, new List<String> {
						r.trim()
					}));
				}
			}
		}
	}

	public static ValidationResult validate(final List<Recipient> recipients, final Boolean sendNow) {
		if (Collection.isEmpty(recipients)) {
			return new ValidationResult(Label.AtLeastOneRecipientIsRequired);
		}

		ValidationResult result = new ValidationResult();
		for (Recipient r : recipients) {
			result.add(validate(r, sendNow));
			// TODO: Check other recipients? Use more specific error messages.
			// TODO: Keep track of previous/next. Mandate role-only recipients after Agent. Editors and Intermediaries have special rules too.
		}

		return result;
	}

	public static ValidationResult validate(final Recipient recipient, final Boolean sendNow) {
		if (recipient == null) {
			return new ValidationResult(Label.UndefinedRecipient);
		}

		ValidationResult result = new ValidationResult();
		if (String.isBlank(recipient.email)) {
			// Allow incomplete recipients when envelope is in draft mode (DFS-4613). A placeholder role is OK.
			if (sendNow && !recipient.isSigningGroup) {
				result.add(Label.EmailRequired);
			} else if (!sendNow && (recipient.role == null || String.isBlank(recipient.role.name))) {
				result.add(Label.PlaceholderRecipientMustHaveRole);
			}
		}
		// TODO: Check other recipient types?
		// TODO: Check signing groups are valid
		// TODO: Check other required fields (e.g. name)

		return result;
	}

	public static List<Recipient> convert(final List<Recipient__c> recipients) {
		List<Recipient> result = new List<Recipient>();
		if (recipients != null) {
			for (Recipient__c recipient : recipients) {
				result.add(DB.convert(recipient));
			}
		}
		return result;
	}

	@TestVisible
	private class Database {

		@TestVisible
		private Recipient convert(final Recipient__c r) {
			if (r == null) return null;

			return new Recipient(
				r.Id,
				r.Type__c,
				Integer.valueOf(r.Sequence__c),
				Integer.valueOf(r.RoutingOrder__c),
				new Recipient.Role(r.Role__c, null),
				r.Name,
				r.Email__c,
				r.SigningGroupId__c != null || String.isNotBlank(r.SigningGroupName__c)
					? new Recipient.SigningGroup(Integer.valueOf(r.SigningGroupId__c), r.SigningGroupName__c) : null,
				r.SmsPhoneNumber__c,
				new Recipient.Authentication(
					r.AccessCode__c,
					r.IdCheckRequired__c == true,
					r.IdCheckRequired__c == true && String.isNotBlank(r.SmsPhoneNumber__c)
						? new List<String> { r.SmsPhoneNumber__c } : null),
				r.Note__c,
				new Recipient.EmailSettings(
					r.Language__c,
					Localization.getLabel(r.Language__c),
					r.EmailSubject__c,
					r.EmailMessage__c),
				r.HostName__c,
				r.HostEmail__c,
				r.SignNow__c == true,
				String.isNotBlank(r.SourceId__c) ? new Entity(Id.valueOf(r.SourceId__c), r.Name, null) : null);
		}

		@TestVisible
		private Recipient__c convert(final Recipient r, final Id envelopeId, final Integer sequence) {
			if (r == null) return null;

			return new Recipient__c(
				Envelope__c = envelopeId,
				Id = r.Id,
				Sequence__c = sequence,
				Type__c = r.type,
				RoutingOrder__c = r.routingOrder,
				Role__c = r.role == null ? null : r.role.name,
				Name = r.name,
				Email__c = r.email,
				SigningGroupId__c = r.signingGroup == null ? null : r.signingGroup.id,
				SigningGroupName__c = r.signingGroup == null ? null : r.signingGroup.name,
				SmsPhoneNumber__c = r.authentication == null || Collection.isEmpty(r.authentication.smsPhoneNumbers)
					? null : r.authentication.smsPhoneNumbers[0],
				AccessCode__c = r.authentication == null ? null : r.authentication.accessCode,
				IdCheckRequired__c = r.authentication == null ? false : r.authentication.idCheckRequired == true,
				Note__c = r.note,
				Language__c = r.emailSettings == null ? null : r.emailSettings.language,
				EmailSubject__c = r.emailSettings == null ? null : r.emailSettings.subject,
				EmailMessage__c = r.emailSettings == null ? null : r.emailSettings.message,
				HostName__c = r.hostName,
				HostEmail__c = r.hostEmail,
				SignNow__c = r.signNow == true,
				SourceId__c = r.source == null ? null : r.source.id);
		}

		public Set<String> queryRoles(final Id envelopeId) {
			Permissions.verifyIsQueryable('Recipient__c', new List<String> { 'Role__c' });

			Set<String> roles = new Set<String>();
			for (Recipient__c r : [SELECT Role__c FROM Recipient__c WHERE Envelope__c = :envelopeId]) {
				if (String.isNotBlank(r.Role__c)) roles.add(r.Role__c);
			}
			return roles;
		}

		@TestVisible
		private Integer queryMaxSequence(final Id envelopeId) {
			Integer sequence = 0;
			List<AggregateResult> maxSequence = [
				SELECT MAX(Sequence__c) maxSequence
				FROM Recipient__c
				WHERE Envelope__c = :envelopeId
			];
			if (Collection.isNotEmpty(maxSequence)) {
				Object obj = maxSequence[0].get('maxSequence');
				sequence = obj == null ? 0 : Integer.valueOf(obj);
			}
			return sequence;
		}

		private List<Recipient__c> queryRecipientsInternal(final Id envelopeId, final Boolean orderBySequence) {
			Permissions.verifyIsQueryable('Recipient__c', new List<String> {
				'Id', 'Sequence__c', 'Name', 'Email__c', 'RoutingOrder__c', 'Type__c', 'Role__c', 'AccessCode__c',
				'IdCheckRequired__c', 'SmsPhoneNumber__c', 'Note__c', 'Language__c', 'EmailSubject__c', 'EmailMessage__c',
				'HostName__c', 'HostEmail__c', 'SignNow__c', 'SigningGroupId__c', 'SigningGroupName__c', 'SourceId__c'
			});

			if (orderBySequence) {
				return [
					SELECT Id, Sequence__c, Name, Email__c, RoutingOrder__c, Type__c, Role__c, AccessCode__c,
						IdCheckRequired__c, SmsPhoneNumber__c, Note__c, Language__c, EmailSubject__c, EmailMessage__c,
						HostName__c, HostEmail__c, SignNow__c, SigningGroupId__c, SigningGroupName__c, SourceId__c
					FROM Recipient__c
					WHERE Envelope__c = :envelopeId
					ORDER BY Sequence__c
				];
			} else { // Order by routing order
				return [
					SELECT Id, Sequence__c, Name, Email__c, RoutingOrder__c, Type__c, Role__c, AccessCode__c,
						IdCheckRequired__c, SmsPhoneNumber__c, Note__c, Language__c, EmailSubject__c, EmailMessage__c,
						HostName__c, HostEmail__c, SignNow__c, SigningGroupId__c, SigningGroupName__c, SourceId__c
					FROM Recipient__c
					WHERE Envelope__c = :envelopeId
					ORDER BY RoutingOrder__c
				];
			}
		}

		public List<Recipient> queryRecipients(final Id envelopeId, final Boolean orderBySequence) {
			return convert(queryRecipientsInternal(envelopeId, orderBySequence));
		}

		@TestVisible
		private List<Recipient> updateRecipientSequence(final Id envelopeId, final Boolean orderBySequence) {
			List<Recipient__c> rs = queryRecipientsInternal(envelopeId, orderBySequence);
			Integer sequence = 1;
			for (Recipient__c r : rs) {
				r.Sequence__c = sequence++;
			}
			update rs;
			return convert(rs);
		}

		public List<Recipient> insertRecipients(final Id envelopeId, final List<Recipient> recipients) {
			Permissions.verifyIsCreateable('Recipient__c', new List<String> {
				'Sequence__c', 'Name', 'Email__c', 'RoutingOrder__c', 'Type__c', 'Role__c', 'AccessCode__c',
				'IdCheckRequired__c', 'SmsPhoneNumber__c', 'Note__c', 'Language__c', 'EmailSubject__c', 'EmailMessage__c',
				'HostName__c', 'HostEmail__c', 'SignNow__c', 'SigningGroupId__c', 'SigningGroupName__c', 'SourceId__c'
			});

			List<Recipient> result = new List<Recipient>();
			if (recipients != null) {
				List<Recipient__c> rs = new List<Recipient__c>();
				Integer sequence = queryMaxSequence(envelopeId);
				for (Recipient r : recipients) {
					rs.add(convert(r, envelopeId, ++sequence));
				}
				insert rs;

				result.addAll(convert(rs));
			}
			return result;
		}

		private void verifySource(final Entity source) {
			if (source == null || !source.isValid) throw new DocuSignException(Label.InvalidSource);
		}

		private void verifyRelatedContacts(final EnvelopeConfiguration.RelatedContacts relatedContacts) {
			if (relatedContacts == null
				|| Collection.isEmpty(relatedContacts.fieldMap)
				|| String.isBlank(relatedContacts.relationship))
				throw new DocuSignException(Label.InvalidRelatedContact);
		}

		public String queryRelatedObjectName(final Entity source, final String relationship) {
			String relatedObjectName = null;
			if (source != null) {
				Id sourceId = source.id;
				String q = String.format('SELECT (SELECT Id FROM {0}) FROM {1} WHERE Id = :sourceId LIMIT 1',
					new List<String> { relationship, String.escapeSingleQuotes(source.type) });
				List<SObject> objs = System.Database.query(q);
				if (Collection.isNotEmpty(objs)) {
					List<SObject> children = objs[0].getSObjects(relationship);
					if (Collection.isNotEmpty(children)) {
						relatedObjectName = children[0].getSObjectType().getDescribe().getName();
					}
				}
			}
			return relatedObjectName;
		}

		public List<String> getFieldNames(final Map<String, String> fieldMap) {
			List<String> fieldNames = new List<String>(fieldMap.values());
			fieldNames.add('Id');
			fieldNames.add('CreatedDate');
			return fieldNames;
		}

		@TestVisible
		private String getValue(final Map<String, String> fieldMap, final SObject obj, final String key) {
			String field = fieldMap.get(key);
			if (String.isNotBlank(field)) {
				return (String)obj.get(field);
			}
			return null;
		}

		@TestVisible
		private Recipient.Authentication getAuthentication(final String accessCode, final String smsPhoneNumber) {
			Boolean useSms = String.isNotBlank(smsPhoneNumber);
			if (String.isNotBlank(accessCode) || useSms) {
				return new Recipient.Authentication(accessCode, useSms,
					useSms ? new List<String> { smsPhoneNumber } : null);
			}
			return null;
		}

		public List<Recipient> queryRelatedContacts(
			final Entity source,
			final EnvelopeConfiguration.RelatedContacts relatedContacts,
			final Map<String, Recipient.SigningGroup> signingGroups) {

			verifySource(source);
			verifyRelatedContacts(relatedContacts);

			List<String> fieldNames = getFieldNames(relatedContacts.fieldMap);
			Permissions.verifyIsQueryable(queryRelatedObjectName(source, relatedContacts.relationship), fieldNames);

			List<Recipient> recipients = new List<Recipient>();
			Id sourceId = source.id;
			String q = String.format('SELECT Id, (SELECT {0} FROM {1}) FROM {2} WHERE Id = :sourceId',
				new List<String> {
					Collection.mkString(fieldNames, ','),
					relatedContacts.relationship, String.escapeSingleQuotes(source.type)
				});
			for (SObject parent : System.Database.query(q)) {
				List<SObject> contacts = parent.getSObjects(relatedContacts.relationship);
				if (contacts != null) {
					for (SObject contact : contacts) {
						String fullName = StringUtils.mkName(getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_FIRST_NAME),
							getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_LAST_NAME));
						String email = getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_EMAIL);
						String sgName = getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_SIGNING_GROUP);
						String roleName = getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_ROLE);
						Recipient.Role role = String.isBlank(roleName) ? null : new Recipient.Role(roleName, 0);

						if (relatedContacts.isSigningGroup && String.isblank(fullName) && String.isblank(email)) {
							if (String.isNotBlank(sgName) && signingGroups.containsKey(sgName.toLowerCase())) {
								recipients.add(Recipient.fromSigningGroup(
									StringUtils.parseInteger(
										getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_ROUTING_ORDER), 1),
									role,
									signingGroups.get(sgName),
									getAuthentication(
										getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_ACCESS_CODE),
										getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_SMS)),
									StringUtils.replaceNoteTags(
										getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_NOTE)))
									.withSource(new Entity(contact.Id)));
							} else if (String.isBlank(sgName)) {
								throw new DocuSignException(Label.UndefinedSigningGroup);
							} else {
								throw new DocuSignException(Label.SigningGroupNotFound);
							}
						} else if (relatedContacts.isSignInPerson) {
							recipients.add(Recipient.newInPersonSigner(
								StringUtils.parseInteger(
									getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_ROUTING_ORDER), 1),
								role,
								getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_SIGN_IN_PERSON),
								null,
								fullName,
								email,
								getAuthentication(
									getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_ACCESS_CODE),
									getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_SMS)),
								StringUtils.replaceNoteTags(
									getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_NOTE)),
								StringUtils.parseBoolean(getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_SIGN_NOW)))
								.withSource(new Entity(contact.Id)));
						} else {
							recipients.add(Recipient.newRecipient(
								StringUtils.parseInteger(
									getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_ROUTING_ORDER), 1),
								Recipient.TYPE_SIGNER, // TODO: Enable type for CRL/CRCL
								role,
								fullName,
								email,
								getAuthentication(
									getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_ACCESS_CODE),
									getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_SMS)),
								StringUtils.replaceNoteTags(getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_NOTE)),
								StringUtils.parseBoolean(getValue(relatedContacts.fieldMap, contact, EnvelopeConfiguration.KEY_SIGN_NOW)))
								.withSource(new Entity(contact.Id)));
						}
					}
				}
			}
			return recipients;
		}

		public Set<String> querySigningGroups(final Entity source,
			final EnvelopeConfiguration.RelatedContacts relatedContacts) {

			verifySource(source);
			verifyRelatedContacts(relatedContacts);

			Set<String> sgs = new Set<String>();
			if (relatedContacts.isSigningGroup) {
				String sgField = relatedContacts.fieldMap.get(EnvelopeConfiguration.KEY_SIGNING_GROUP);

				Permissions.verifyIsQueryable(queryRelatedObjectName(source, relatedContacts.relationship),
					new List<String> { sgField });

				Id sourceId = source.id;
				String query = String.format('SELECT Id, (SELECT {0} FROM {1}) FROM {2} WHERE Id = :sourceId',
					new List<String> { sgField, relatedContacts.relationship, String.escapeSingleQuotes(source.type) });
				for (SObject parent : System.Database.query(query)) {
					List<SObject> contacts = parent.getSObjects(relatedContacts.relationship);
					if (contacts != null) {
						for (SObject contact : contacts) {
							String sg = (String)contact.get(sgField);
							if (String.isNotBlank(sg)) {
								sgs.add(sg.trim().toLowerCase());
							}
						}
					}
				}
			}
			return sgs;
		}

		public List<Recipient> deleteRecipients(final Id envelopeId, final Set<Id> recipientIds) {
			Permissions.verifyIsDeletable('Recipient__c');

			Boolean result = false;
			if (recipientIds != null) {
				List<Recipient__c> rs = new List<Recipient__c>();
				for (Id id : recipientIds) {
					rs.add(new Recipient__c(Id = id));
				}
				delete rs;
				result = true;
			}
			return updateRecipientSequence(envelopeId, true);
		}

		public List<Recipient> upsertRecipients(final Id envelopeId, final List<Recipient> recipients) {
			Permissions.verifyIsCreateable('Recipient__c', new List<String> {
				'Sequence__c', 'Name', 'Email__c', 'RoutingOrder__c', 'Type__c', 'Role__c', 'AccessCode__c',
				'IdCheckRequired__c', 'SmsPhoneNumber__c', 'Note__c', 'Language__c', 'EmailSubject__c', 'EmailMessage__c',
				'HostName__c', 'HostEmail__c', 'SignNow__c', 'SigningGroupId__c', 'SigningGroupName__c', 'SourceId__c'
			});
			Permissions.verifyIsUpdateable('Recipient__c', new List<String> {
				'Sequence__c', 'Name', 'Email__c', 'RoutingOrder__c', 'Type__c', 'Role__c', 'AccessCode__c',
				'IdCheckRequired__c', 'SmsPhoneNumber__c', 'Note__c', 'Language__c', 'EmailSubject__c', 'EmailMessage__c',
				'HostName__c', 'HostEmail__c', 'SignNow__c', 'SigningGroupId__c', 'SigningGroupName__c', 'SourceId__c'
			});

			List<Recipient> result = null;
			if (Collection.isNotEmpty(recipients)) {
				final List<Recipient__c> rs = new List<Recipient__c>();
				for (Recipient r : recipients) {
					rs.add(convert(r, envelopeId, null));
				}
				upsert rs;
				result = updateRecipientSequence(envelopeId, false);
			}
			return result;
		}
	}

	public static List<Recipient> getRecipients(final String sObjectType, final Set<Id> sObjectIds) {
		Permissions.verifyIsDocuSignUser();

		List<Recipient> result = null;
		for (RecipientResolver rr : RECIPIENT_RESOLVERS) {
			if (rr.canResolveRecipients(sObjectType)) {
				result = rr.getRecipients(sObjectType, sObjectIds);
				break;
			}
		}
		return result;
	}

	private static SearchBehavior getSearchBehavior() {
		SearchBehavior result = SearchBehavior.DiscreteMatchBeginning;
		String sb = AccountSettings__c.getOrgDefaults().RecipientSearchBehavior__c;
		if (sb == 'CompoundMatchBeginning') {
			result = SearchBehavior.CompoundMatchBeginning;
		} else if (sb == 'CompoundMatchExact') {
			result = SearchBehavior.CompoundMatchExact;
		} else if (sb == 'CompoundMatchAny') {
			result = SearchBehavior.CompoundMatchAny;
		} else if (sb == 'DiscreteMatchExact') {
			result = SearchBehavior.DiscreteMatchExact;
		} else if (sb == 'DiscreteMatchAny') {
			result = SearchBehavior.DiscreteMatchAny;
		}
		return result;
	}

	public static List<Recipient> searchRecipients(final String sObjectType, final String firstName,
		final String lastName) {

		Permissions.verifyIsDocuSignUser();

		List<Recipient> result = null;
		for (RecipientResolver rr : RECIPIENT_RESOLVERS) {
			if (rr.canSearchRecipients(sObjectType)) {
				result = rr.searchRecipients(sObjectType, firstName, lastName, getSearchBehavior());
				break;
			}
		}
		return result;
	}

	@TestVisible
	private class MergeResult {
		public Recipient recipient { get; private set; }
		public Boolean isMerged { get; private set; }

		public MergeResult(final Recipient recipient, final Boolean isMerged) {
			this.recipient = recipient;
			this.isMerged = isMerged;
		}
	}

	public static List<Recipient.Role> getDefaultRoles() {
		if (DEFAULT_ROLES == null) {
			DEFAULT_ROLES = new List<Recipient.Role>();
			for (RoleSettings__c s : RoleSettings__c.getAll().values()) {
				DEFAULT_ROLES.add(new Recipient.Role(s.Name, Integer.valueOf(s.Value__c)));
			}
			DEFAULT_ROLES.sort();
		}
		return DEFAULT_ROLES;
	}

	@TestVisible
	private static Recipient.Role resolveRole(final String roleName) {
		Recipient.Role result = null;

		if (String.isNotBlank(roleName)) {
			List<Recipient.Role> roles = getDefaultRoles();
			String rn = roleName.trim();
			for (Recipient.Role r : roles) {
				if (rn == r.name) {
					result = r;
					break;
				}
			}
		}

		if (result == null) {
			result = new Recipient.Role(roleName, 0);
		}

		return result;
	}

	@TestVisible
	private static MergeResult mergeAvailableRole(final Recipient recipient, final Set<String> rolesInUse) {
		MergeResult result = null;
		Recipient.Role rr = null;
		if (rolesInUse != null
			&& recipient.role != null
			&& String.isNotBlank(recipient.role.name)
			&& ((recipient.id != null && rolesInUse.contains(recipient.role.name))
			|| !rolesInUse.contains(recipient.role.name))) {

			// either already added to envelope with a valid role or not in use
			rr = resolveRole(recipient.role.name);
		}

		if (rr == null || rr.value == 0) {
			List<Recipient.Role> roles = getDefaultRoles();
			for (Recipient.Role role : roles) {
				if (rolesInUse != null && !rolesInUse.contains(role.name)) {
					rr = role;
					break;
				}
			}
		}

		if (rr == null || rr.value == 0) {
			// TODO: Is it appropriate to add a role with value 0?
			return new MergeResult(recipient.withRole(rr), false);
		}

		return new MergeResult(recipient.withRole(rr), true);
	}

	@TestVisible
	private static List<Recipient> mergeDefaultSettings(final Id envelopeId, final List<Recipient> recipients) {
		if (Collection.isEmpty(recipients)) {
			LOG.warn('Skipping default settings merge as one or more parameters is undefined');
			return recipients;
		}

		Set<String> rolesInUse = DB.queryRoles(envelopeId);
		List<Recipient> mergedRecipients = new List<Recipient>();
		for (Recipient r : recipients) {
			MergeResult mr = mergeAvailableRole(r, rolesInUse);
			if (mr.isMerged && mr.recipient != null && mr.recipient.role != null) {
				mergedRecipients.add(mr.recipient);
				if (String.isNotBlank(mr.recipient.role.name)) rolesInUse.add(mr.recipient.role.name);
			} else {
				if (mr.recipient == null) throw new DocuSignException(Label.UndefinedRecipient);

				// TODO: Throw exception? Currently just ignoring recipients that don't have a role.
				LOG.warn('Did not merge recipient \'' + mr.recipient.id + '\' role \''
					+ (mr.recipient.role != null ? mr.recipient.role.name : '')
					+ '\' because there were no available roles left');
				mergedRecipients.add(mr.recipient);
			}
		}
		return mergedRecipients;
	}

	@TestVisible
	private static MergeResult mergeEmailSettings(
		final Recipient recipient,
		final Recipient.EmailSettings customSettings,
		final Recipient.EmailSettings defaultSettings) {

		if (customSettings == null && defaultSettings == null) {
			return new MergeResult(recipient, false);
		}

		if (customSettings != null) {
			String loc = String.isNotBlank(customSettings.language) ? customSettings.language : defaultSettings.language;
			return new MergeResult(recipient.withEmailSettings(new Recipient.EmailSettings(
				loc,
				Localization.getLabel(loc),
				String.isNotBlank(customSettings.subject) ? customSettings.subject : defaultSettings.subject,
				String.isNotBlank(customSettings.message) ? customSettings.message : defaultSettings.message)),
				true);
		}
		return new MergeResult(recipient.withEmailSettings(defaultSettings), true);
	}

	@TestVisible
	private static MergeResult mergeTemplateRoleWithRole(
		final Recipient recipient,
		final String role,
		final Map<String, String> roleToTemplateRoles) {

		MergeResult result = null;
		if (String.isNotBlank(role) && Collection.containsKey(roleToTemplateRoles, role)) {
			String rr = roleToTemplateRoles.get(role);
			if (String.isNotBlank(rr)) {
				result = new MergeResult(recipient.withRole(resolveRole(rr)), true);
			} else {
				LOG.warn('Blank template role for contact role: ' + role);
				result = new MergeResult(recipient, false);
			}
		} else {
			// No type mapped to contact role
			result = new MergeResult(recipient, false);
		}

		return result;
	}

	@TestVisible
	private static MergeResult mergeNoteWithRole(
		final Recipient recipient,
		final String role,
		final Map<String, String> roleToNotes) {

		MergeResult result = null;
		if (String.isNotBlank(role)) {
			if (Collection.containsKey(roleToNotes, role)) {
				result = new MergeResult(recipient.withNote(roleToNotes.get(role)), true);
			} else if (Collection.containsKey(roleToNotes, EnvelopeConfiguration.DEFAULT_NOTE)) {
				result = new MergeResult(recipient.withNote(roleToNotes.get(EnvelopeConfiguration.DEFAULT_NOTE)), true);
			}
		}

		if (result == null) {
			result = new MergeResult(recipient, false);
		}

		return result;
	}

	@TestVisible
	private static MergeResult mergeTypeWithRole(
		final Recipient recipient,
		final String role,
		final Map<String, EnvelopeConfiguration.RecipientType> roleToRecipientTypes) {

		MergeResult result = null;
		if (String.isNotBlank(role) && Collection.containsKey(roleToRecipientTypes, role)) {
			EnvelopeConfiguration.RecipientType rt = roleToRecipientTypes.get(role);
			if (rt != null) {
				result = new MergeResult(recipient.withType(rt.type, rt.signNow), true);
			} else {
				LOG.warn('Null recipient type for contact role: ' + role);
				result = new MergeResult(recipient, false);
			}

		} else {
			// No type mapped to contact role
			result = new MergeResult(recipient, false);
		}

		return result;
	}

	@TestVisible
	private static MergeResult mergeRoleType(
		final Recipient recipient,
		final Integer index,
		final List<EnvelopeConfiguration.RecipientRoleType> recipientRoleTypes) {

		// Get first available role
		MergeResult result = null;
		if (Collection.isNotEmpty(recipientRoleTypes)) {
			// stop if we've reached the end of recipient type specified in the custom List
			if (recipientRoleTypes.size() <= index) {
				LOG.warn('No remaining type-roles to assign');
				result = new MergeResult(recipient, false);
			} else {
				EnvelopeConfiguration.RecipientRoleType rt = recipientRoleTypes[index];
				if (String.isNotBlank(rt.role) && rt.type != null) {
					result = new MergeResult(
						recipient
							.withRole(resolveRole(rt.role))
							.withType(rt.type.type, rt.type.signNow),
						true);
				} else {
					LOG.warn('Blank recipient type at index ' + index);
					result = new MergeResult(recipient, false);
				}
			}
		}

		if (result == null) {
			// No types mapped to roles via RT parameter
			result = new MergeResult(recipient, false);
		}

		return result;
	}

	private static Set<String> markRoleUsed(final MergeResult result, final Set<String> rolesInUse) {
		if (result.isMerged
			&& result.recipient != null
			&& result.recipient.role != null
			&& String.isNotBlank(result.recipient.role.name)) {

			rolesInUse.add(result.recipient.role.name);
		}
		return rolesInUse;
	}

	@TestVisible
	private static List<Recipient> mergeCustomSettings(
		final Id envelopeId,
		final List<Recipient> recipients,
		final Recipient.EmailSettings emailSettings,
		final EnvelopeConfiguration.RecipientSettings recipientSettings) {

		if (envelopeId == null
			|| Collection.isEmpty(recipients)
			|| emailSettings == null
			|| recipientSettings == null) {

			LOG.warn('Skipping custom settings merge as one or more parameters is undefined');
			return recipients;
		}

		Set<String> rolesInUse = DB.queryRoles(envelopeId);
		Recipient.EmailSettings defaultSettings = Localization.getEmailSettingsForCurrentLanguage();
		List<Recipient> mergedRecipients = new List<Recipient>();
		Integer index = 0;
		for (Recipient r : recipients) {
			Boolean isTypeMerged = false, isRoleMerged = false;
			MergeResult result = mergeEmailSettings(r, emailSettings, defaultSettings);

			String role = null;
			if (r.role != null && String.isNotBlank(r.role.name)) {
				role = r.role.name;
			}

			if (String.isNotBlank(role)) {
				role = role.toLowerCase(); // Keys are all lowercase
			}

			result = mergeNoteWithRole(result.recipient, role, recipientSettings.roleToNotes);
			result = mergeTypeWithRole(result.recipient, role, recipientSettings.roleToRecipientTypes);
			isTypeMerged = result.isMerged;
			result = mergeTemplateRoleWithRole(result.recipient, role, recipientSettings.roleToTemplateRoles);
			rolesInUse = markRoleUsed(result, rolesInUse);
			isRoleMerged = result.isMerged;

			// Fallback to RT (??) parameter or next available role
			if (!isTypeMerged || !isRoleMerged) {
				result = mergeRoleType(result.recipient, index, recipientSettings.recipientRoleTypes);
				rolesInUse = markRoleUsed(result, rolesInUse);
				if (!isRoleMerged && !result.isMerged) {
					result = mergeAvailableRole(result.recipient, rolesInUse);
					rolesInUse = markRoleUsed(result, rolesInUse);
				}
			}

			mergedRecipients.add(result.recipient);
			++index;
		}
		return mergedRecipients;
	}

	@TestVisible
	private static List<Recipient> mergeUserTags(final List<Recipient> recipients) {
		if (recipients == null) return recipients;

		List<Recipient> result = new List<Recipient>();
		for (Recipient r : recipients) {
			result.add(mergeUserTags(r));
		}

		return result;
	}

	@TestVisible
	private static Recipient mergeUserTags(final Recipient recipient) {
		if (recipient == null) return recipient;

		Recipient result = recipient;
		if (recipient.emailSettings != null && (String.isNotBlank(recipient.emailSettings.subject)
			|| String.isNotBlank(recipient.emailSettings.message))) {

			result = result.withEmailSettings(result.emailSettings
				.withSubject(StringUtils.replaceUserTags(result.emailSettings.subject))
				.withMessage(StringUtils.replaceUserTags(result.emailSettings.message)));
		}
		return result;
	}

	public static List<Recipient> addEnvelopeRecipients(final Id envelopeId, final List<Recipient> recipients) {
		return addEnvelopeRecipients(envelopeId, recipients, null, null);
	}

	public static List<Recipient> addEnvelopeRecipients(
		final Id envelopeId,
		final List<Recipient> recipients,
		final Recipient.EmailSettings emailSettings,
		final EnvelopeConfiguration.RecipientSettings recipientSettings) {

		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);
		if (Collection.isEmpty(recipients)) throw new DocuSignException(Label.UndefinedRecipient);

		List<Recipient> result = new List<Recipient>();
		if (emailSettings == null && recipientSettings == null) {
			// FIXME: Need to add default role and signer type mappings even when custom buttons are undefined.
			return DB.insertRecipients(envelopeId, mergeUserTags(mergeDefaultSettings(envelopeId, recipients)));
		}
		return DB.insertRecipients(envelopeId, mergeUserTags(mergeCustomSettings(envelopeId, recipients, emailSettings,
			recipientSettings)));
	}

	public static List<Recipient> resolveRelatedContacts(
		final Entity source,
		final EnvelopeConfiguration.RelatedContacts relatedContacts,
		final Map<String, Recipient.SigningGroup> signingGroups) {

		List<Recipient> recipients = null;
		if (relatedContacts != null) {
			recipients = DB.queryRelatedContacts(source, relatedContacts, signingGroups);
		}
		return recipients == null ? new List<Recipient>() : recipients;
	}

	public static List<Recipient> resolveDefaultRecipients(
		final Entity source,
		final Recipient.EmailSettings defaultEmailSettings) {

		if (source == null) return null;

		List<Recipient> result = getRecipients(source.type, new Set<Id> { source.id });
		if (result != null && defaultEmailSettings != null) {
			for (Integer i = 0; i < result.size(); i++) {
				result[i] = result[i].withEmailSettings(defaultEmailSettings);
			}
		}
		return result;
	}

	public static List<Recipient> resolveCustomRecipients(
		final EnvelopeConfiguration.Recipients customRecipients,
		final Map<String, Recipient.SigningGroup> signingGroups,
		final Recipient.EmailSettings defaultEmailSettings) {

		List<Recipient> recipients = new List<Recipient>();
		if (customRecipients != null && customRecipients.recipients != null) {
			for (EnvelopeConfiguration.CustomRecipient r : customRecipients.recipients) {
				recipients.add(r.toRecipient(signingGroups).withEmailSettings(
					defaultEmailSettings != null ? defaultEmailSettings : null));
			}
		}
		return recipients;
	}

	@TestVisible
	private static Set<String> getSigningGroups(final Entity source,
		final EnvelopeConfiguration.RecipientSettings recipientSettings) {

		Set<String> signingGroups = new Set<String>();
		if (recipientSettings != null) {
			if (recipientSettings.hasRelatedContacts) {
				for (EnvelopeConfiguration.RelatedContacts rc : recipientSettings.relatedContacts) {
					signingGroups.addAll(DB.querySigningGroups(source, rc));
				}
			}
			if (recipientSettings.hasRecipients) {
				for (EnvelopeConfiguration.CustomRecipient r : recipientSettings.recipients.recipients) {
					if (r.isSigningGroup) {
						signingGroups.add(r.signingGroupName.trim().toLowerCase());
					}
				}
			}
		}
		return signingGroups;
	}

	public static Map<String, Recipient.SigningGroup> resolveSigningGroups(
		final Entity source,
		final EnvelopeConfiguration.RecipientSettings recipientSettings) {

		Map<String, Recipient.SigningGroup> resolvedSigningGroups = new Map<String, Recipient.SigningGroup>();
		if (recipientSettings != null) {
			Set<String> targetSigningGroups = getSigningGroups(source, recipientSettings);
			if (Collection.isNotEmpty(targetSigningGroups)) {
				if (!AccountFeatures.getInstance().signingGroups) throw new DocuSignException(Label.SigningGroupsProhibited);

				List<SigningGroup> sgs = EnvelopeAPI.getInstance().getSigningGroups();
				if (sgs != null) {
					for (SigningGroup sg : sgs) {
						if (String.isNotBlank(sg.name)) {
							String key = sg.name.toLowerCase();
							if (targetSigningGroups.contains(key)) {
								resolvedSigningGroups.put(key, sg.toRecipientSigningGroup());
							}
						}
					}
				}

				if (resolvedSigningGroups.size() != targetSigningGroups.size()) {
					for (String sg : targetSigningGroups) {
						if (!resolvedSigningGroups.containsKey(sg)) {
							LOG.error('Signing group not found: ' + sg);
						}
					}
					throw new DocuSignException(Label.SigningGroupNotFound);
				}
			}
		}

		return resolvedSigningGroups;
	}

	public static List<Recipient> updateEnvelopeRecipients(
		final Id envelopeId,
		final List<Recipient> originalRecipients,
		final List<Recipient> updatedRecipients) {

		// Create two sets of IDs: original and updated.
		Set<Id> originalIds = new Set<Id>();
		if (originalRecipients != null) {
			for (Recipient r : originalRecipients) {
				originalIds.add(r.id);
			}
		}

		Set<Id> updatedIds = new Set<Id>();
		if (updatedRecipients != null) {
			for (Recipient r : updatedRecipients) {
				if (r.id != null) updatedIds.add(r.id);
			}
		}

		DB.deleteRecipients(envelopeId, Collection.difference(originalIds, updatedIds));
		return DB.upsertRecipients(envelopeId, mergeUserTags(updatedRecipients));
	}
}
