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

	@TestVisible
	private static List<Recipient> convert(final List<Recipient__c> recipients) {
		List<Recipient> result = new List<Recipient>();
		if (recipients != null) {
			for (Recipient__c recipient : recipients) {
				result.add(convert(recipient));
			}
		}
		return result;
	}

	@TestVisible
	private static Recipient convert(final Recipient__c recipient) {
		if (recipient == null) return null;

		return new Recipient(
			recipient.Id,
			recipient.Type__c,
			Integer.valueOf(recipient.Sequence__c),
			Integer.valueOf(recipient.RoutingOrder__c),
			new Recipient.Role(recipient.Role__c, null),
			recipient.Name,
			recipient.Email__c,
			recipient.SigningGroupId__c != null || String.isNotBlank(recipient.SigningGroupName__c)
				? new Recipient.SigningGroup(Integer.valueOf(recipient.SigningGroupId__c), recipient.SigningGroupName__c) : null,
			recipient.SmsPhoneNumber__c,
			new Recipient.Authentication(
				recipient.AccessCode__c,
				recipient.IdCheckRequired__c == true,
				recipient.IdCheckRequired__c == true && String.isNotBlank(recipient.SmsPhoneNumber__c)
					? new List<String> { recipient.SmsPhoneNumber__c } : null),
			recipient.Note__c,
			new Recipient.EmailSettings(
				recipient.Language__c,
				Localization.getLabel(recipient.Language__c),
				recipient.EmailSubject__c,
				recipient.EmailMessage__c),
			recipient.HostName__c,
			recipient.HostEmail__c,
			recipient.SignNow__c == true,
			String.isNotBlank(recipient.SourceId__c)
				? new Entity(Id.valueOf(recipient.SourceId__c), recipient.Name, null) : null);
	}

	@TestVisible
	private static Recipient__c convert(final Recipient recipient, final Id envelopeId) {
		Recipient__c r = new Recipient__c(
			Envelope__c = envelopeId,
			Id = recipient.Id,
			Type__c = recipient.type,
			RoutingOrder__c = recipient.routingOrder,
			Role__c = recipient.role == null ? null : recipient.role.name,
			Name = recipient.name,
			Email__c = recipient.email,
			SigningGroupId__c = recipient.signingGroup == null ? null : recipient.signingGroup.id,
			SigningGroupName__c = recipient.signingGroup == null ? null : recipient.signingGroup.name,
			SmsPhoneNumber__c = recipient.authentication == null || Collection.isEmpty(recipient.authentication.smsPhoneNumbers)
				? null : recipient.authentication.smsPhoneNumbers[0],
			AccessCode__c = recipient.authentication == null ? null : recipient.authentication.accessCode,
			IdCheckRequired__c = recipient.authentication == null ? false : recipient.authentication.idCheckRequired == true,
			Note__c = recipient.note,
			Language__c = recipient.emailSettings == null ? null : recipient.emailSettings.language,
			EmailSubject__c = recipient.emailSettings == null ? null : recipient.emailSettings.subject,
			EmailMessage__c = recipient.emailSettings == null ? null : recipient.emailSettings.message,
			HostName__c = recipient.hostName,
			HostEmail__c = recipient.hostEmail,
			SignNow__c = recipient.signNow == true,
			SourceId__c = recipient.source == null ? null : recipient.source.id);

		if (recipient.sequence != null) {
			r.Sequence__c = recipient.sequence;
		}

		return r;
	}

	@TestVisible
	private class Database {

		public Set<String> queryRoles(final Id envelopeId) {
			Permissions.verifyIsQueryable('Recipient__c', new List<String> { 'Role__c' });

			Set<String> roles = new Set<String>();
			for (Recipient__c r : [SELECT Role__c FROM Recipient__c WHERE Envelope__c = :envelopeId]) {
				if (String.isNotBlank(r.Role__c)) roles.add(r.Role__c);
			}
			return roles;
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
			Integer sequence = 1;
			if (Collection.isNotEmpty(recipients)) {
				final List<Recipient__c> dsrs = new List<Recipient__c>();
				for (Recipient r : recipients) {
					dsrs.add(convert(r, envelopeId));
				}
				upsert dsrs;
				result = updateRecipientSequence(envelopeId, false);
			} else {
				result = new List<Recipient>();
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

	public static List<Recipient> saveRecipients(final Id envelopeId, final List<Recipient> recipients) {
		return saveRecipients(envelopeId, recipients, null, null);
	}

	public static List<Recipient> saveRecipients(
		final Id envelopeId,
		final List<Recipient> recipients,
		final Recipient.EmailSettings emailSettings,
		final EnvelopeConfiguration.RecipientSettings recipientSettings) {

		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);
		if (Collection.isEmpty(recipients)) throw new DocuSignException(Label.UndefinedRecipient);

		List<Recipient> result = new List<Recipient>();
		if (emailSettings == null && recipientSettings == null) {
			// FIXME: Need to add default role and signer type mappings even when custom buttons are undefined.
			return DB.upsertRecipients(envelopeId, mergeUserTags(mergeDefaultSettings(envelopeId, recipients)));
		}
		return DB.upsertRecipients(envelopeId, mergeUserTags(mergeCustomSettings(envelopeId, recipients, emailSettings,
			recipientSettings)));
	}
}
