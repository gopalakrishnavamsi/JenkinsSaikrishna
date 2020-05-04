/**
 * This class is the entry point for DocuSign eSignature envelope recipient management. It provides methods to retrieve
 * Salesforce source recipients.
 */
global with sharing class RecipientService {

	@TestVisible
	private static final RecipientService.Database DB = new RecipientService.Database();
	private static final LoggerService LOG = LoggerService.getInstance();
	private static final SObjectType TYPE_RECIPIENT = Recipient__c.getSObjectType();
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

	/**
	 * Validates a list of DocuSign envelope recipients. They are checked for the following:
	 * <ul>
	 *     <li>At least one recipient is defined.</li>
	 *     <li>If sending now and the recipient is not a signing group, the email address must not be blank.</li>
	 *     <li>If not sending now and the email address is blank, the role name must not be blank.</li>
	 * </ul>
	 * <p>
	 * <em>This method is intended for DocuSign internal use only.</em>
	 *
	 * @param recipients The recipients to validate.
	 * @param sendNow Whether the intention is to send the envelope now or to continue preparation.
	 *
	 * @return The result of the validation.
	 */
	public static ValidationResult validate(
		final List<Recipient> recipients,
		final Boolean sendNow) {

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

	@TestVisible
	private static ValidationResult validate(
		final Recipient recipient,
		final Boolean sendNow) {

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

	/**
	 * Converts a list of <code>dfsle__Recipient__c</code> objects to their domain object form.
	 * <p>
	 * <em>This method is intended for DocuSign internal use only.</em>
	 *
	 * @param recipients The recipients to convert.
	 *
	 * @return The converted recipients.
	 */
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
				r.EnvelopeRecipientId__c,
				r.Type__c,
				Integer.valueOf(r.Sequence__c),
				Integer.valueOf(r.RoutingOrder__c),
				new Recipient.Role(r.Role__c, Integer.valueOf(r.RoleValue__c)),
				r.Name,
				r.Email__c,
				r.SigningGroupId__c != null || String.isNotBlank(r.SigningGroupName__c)
					? new SigningGroup(Integer.valueOf(r.SigningGroupId__c), r.SigningGroupName__c) : null,
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
				null, // TODO: Store recipient tabs.
				String.isNotBlank(r.SourceId__c) ? new Entity(Id.valueOf(r.SourceId__c), r.Name, null) : null,
				r.ReadOnly__c == true,
				r.Required__c == true);
		}

		@TestVisible
		private Recipient__c convert(
			final Recipient r,
			final Id envelopeId,
			final Integer sequence) {

			if (r == null) return null;

			return new Recipient__c(
				Envelope__c = envelopeId,
				Id = r.id,
				EnvelopeRecipientId__c = String.isBlank(r.envelopeRecipientId) ? null : r.envelopeRecipientId,
				Sequence__c = sequence,
				Type__c = r.type,
				RoutingOrder__c = r.routingOrder,
				Role__c = r.role == null ? null : r.role.name,
				RoleValue__c = r.role == null || !r.role.hasValue ? null : r.role.value,
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
				SourceId__c = r.source == null ? null : r.source.id,
				ReadOnly__c = r.readOnly == true,
				Required__c = r.required == true);
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

		private List<Recipient__c> queryRecipientsInternal(
			final Id envelopeId,
			final Boolean orderBySequence) {

			Permissions.verifyIsQueryable(TYPE_RECIPIENT, new List<String> {
				'Id',
				'Name',
				Application.namespacePrefix + 'AccessCode__c',
				Application.namespacePrefix + 'Email__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'EnvelopeRecipientId__c',
				Application.namespacePrefix + 'HostEmail__c',
				Application.namespacePrefix + 'HostName__c',
				Application.namespacePrefix + 'IdCheckRequired__c',
				Application.namespacePrefix + 'Language__c',
				Application.namespacePrefix + 'Note__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Role__c',
				Application.namespacePrefix + 'RoleValue__c',
				Application.namespacePrefix + 'RoutingOrder__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'SigningGroupId__c',
				Application.namespacePrefix + 'SigningGroupName__c',
				Application.namespacePrefix + 'SignNow__c',
				Application.namespacePrefix + 'SmsPhoneNumber__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
			});

			if (orderBySequence) {
				return [
					SELECT Id,
						EnvelopeRecipientId__c,
						Sequence__c,
						Name,
						Email__c,
						RoutingOrder__c,
						Type__c,
						Role__c,
						RoleValue__c,
						AccessCode__c,
						IdCheckRequired__c,
						SmsPhoneNumber__c,
						Note__c,
						Language__c,
						EmailSubject__c,
						EmailMessage__c,
						HostName__c,
						HostEmail__c,
						SignNow__c,
						SigningGroupId__c,
						SigningGroupName__c,
						SourceId__c,
						ReadOnly__c,
						Required__c
					FROM Recipient__c
					WHERE Envelope__c = :envelopeId
					ORDER BY Sequence__c
				];
			} else { // Order by routing order
				return [
					SELECT Id,
						EnvelopeRecipientId__c,
						Sequence__c,
						Name,
						Email__c,
						RoutingOrder__c,
						Type__c,
						Role__c,
						RoleValue__c,
						AccessCode__c,
						IdCheckRequired__c,
						SmsPhoneNumber__c,
						Note__c,
						Language__c,
						EmailSubject__c,
						EmailMessage__c,
						HostName__c,
						HostEmail__c,
						SignNow__c,
						SigningGroupId__c,
						SigningGroupName__c,
						SourceId__c,
						ReadOnly__c,
						Required__c
					FROM Recipient__c
					WHERE Envelope__c = :envelopeId
					ORDER BY RoutingOrder__c
				];
			}
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

		public List<Recipient> insertRecipients(
			final Id envelopeId,
			final List<Recipient> recipients) {

			Permissions.verifyIsCreateable(TYPE_RECIPIENT, new List<String> {
				'Name',
				Application.namespacePrefix + 'AccessCode__c',
				Application.namespacePrefix + 'Email__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'EnvelopeRecipientId__c',
				Application.namespacePrefix + 'HostEmail__c',
				Application.namespacePrefix + 'HostName__c',
				Application.namespacePrefix + 'IdCheckRequired__c',
				Application.namespacePrefix + 'Language__c',
				Application.namespacePrefix + 'Note__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Role__c',
				Application.namespacePrefix + 'RoleValue__c',
				Application.namespacePrefix + 'RoutingOrder__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'SigningGroupId__c',
				Application.namespacePrefix + 'SigningGroupName__c',
				Application.namespacePrefix + 'SignNow__c',
				Application.namespacePrefix + 'SmsPhoneNumber__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
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

		public Map<Id, List<Recipient>> insertRecipients(final Map<Id, List<Recipient>> recipients) {
			Permissions.verifyIsCreateable(TYPE_RECIPIENT, new List<String> {
				'Name',
				Application.namespacePrefix + 'AccessCode__c',
				Application.namespacePrefix + 'Email__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'EnvelopeRecipientId__c',
				Application.namespacePrefix + 'HostEmail__c',
				Application.namespacePrefix + 'HostName__c',
				Application.namespacePrefix + 'IdCheckRequired__c',
				Application.namespacePrefix + 'Language__c',
				Application.namespacePrefix + 'Note__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Role__c',
				Application.namespacePrefix + 'RoleValue__c',
				Application.namespacePrefix + 'RoutingOrder__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'SigningGroupId__c',
				Application.namespacePrefix + 'SigningGroupName__c',
				Application.namespacePrefix + 'SignNow__c',
				Application.namespacePrefix + 'SmsPhoneNumber__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
			});

			Map<Id, List<Recipient>> result = new Map<Id, List<Recipient>>();
			if (Collection.isNotEmpty(recipients)) {
				List<Recipient__c> rs = new List<Recipient__c>();
				for (Id eId : recipients.keySet()) {
					List<Recipient> recips = recipients.get(eId);
					if (Collection.isNotEmpty(recips)) {
						Integer sequence = 0;
						for (Recipient r : recips) {
							rs.add(convert(r, eId, ++sequence));
						}
					}
				}
				insert rs;

				for (Recipient__c r : rs) {
					if (r == null || r.Envelope__c == null) continue;

					if (result.containsKey(r.Envelope__c)) {
						result.get(r.Envelope__c).add(convert(r));
					} else {
						result.put(r.Envelope__c, new List<Recipient> { convert(r) });
					}
				}
			}
			return result;
		}

		public List<Recipient> deleteRecipients(final Id envelopeId, final Set<Id> recipientIds) {
			Permissions.verifyIsDeletable(TYPE_RECIPIENT);

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

		public List<Recipient> upsertRecipients(
			final Id envelopeId,
			final List<Recipient> recipients) {

			List<String> fields = new List<String> {
				'Name',
				Application.namespacePrefix + 'AccessCode__c',
				Application.namespacePrefix + 'Email__c',
				Application.namespacePrefix + 'EmailMessage__c',
				Application.namespacePrefix + 'EmailSubject__c',
				Application.namespacePrefix + 'EnvelopeRecipientId__c',
				Application.namespacePrefix + 'HostEmail__c',
				Application.namespacePrefix + 'HostName__c',
				Application.namespacePrefix + 'IdCheckRequired__c',
				Application.namespacePrefix + 'Language__c',
				Application.namespacePrefix + 'Note__c',
				Application.namespacePrefix + 'ReadOnly__c',
				Application.namespacePrefix + 'Required__c',
				Application.namespacePrefix + 'Role__c',
				Application.namespacePrefix + 'RoleValue__c',
				Application.namespacePrefix + 'RoutingOrder__c',
				Application.namespacePrefix + 'Sequence__c',
				Application.namespacePrefix + 'SigningGroupId__c',
				Application.namespacePrefix + 'SigningGroupName__c',
				Application.namespacePrefix + 'SignNow__c',
				Application.namespacePrefix + 'SmsPhoneNumber__c',
				Application.namespacePrefix + 'SourceId__c',
				Application.namespacePrefix + 'Type__c'
			};
			Permissions.verifyIsCreateable(TYPE_RECIPIENT, fields);
			Permissions.verifyIsUpdateable(TYPE_RECIPIENT, fields);

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

	/**
	 * Retrieves a list of DocuSign envelope recipients from Salesforce source objects.
	 * <p>
	 * By default, the Salesforce <code>Account</code>, <code>Case</code>, <code>Contact</code>, <code>Lead</code>,
	 * and <code>Opportunity</code> types are supported. More types may be supported via plugins.
	 *
	 * @param type The Salesforce object type.
	 * @param ids The Salesforce object IDs.
	 *
	 * @return A list of envelope recipients.
	 */
	global static List<Recipient> getRecipients(
		final SObjectType type,
		final Set<Id> ids) {

		if (type == null) throw new DocuSignException(Label.InvalidType);

		List<Recipient> result = null;
		for (RecipientResolver rr : RECIPIENT_RESOLVERS) {
			if (rr.canResolveRecipientSource(type)) {
				result = rr.getSourceRecipients(type, ids);
				break;
			}
		}
		return result;
	}

	public static Boolean canResolveRecipientType(final SObjectType type) {
		for (RecipientResolver rr : RECIPIENT_RESOLVERS) {
			if (rr.canResolveRecipientType(type)) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Reads recipients related to a type.
	 *
	 * @param type The source SObject type.
	 * @param ids The source SObject IDs.
	 * @param relationship The relationship to query.
	 * @param filter Optional result filter.
	 *
	 * @return The resolved recipients.
	 */
	public static List<Recipient> getRelatedRecipients(
		SObjectType type,
		Set<Id> ids,
		Query.Relationship relationship,
		Query.Filter filter) {

		if (type == null) throw new DocuSignException(Label.InvalidType);
		if (relationship == null
			|| String.isBlank(relationship.name)
			|| String.isBlank(relationship.relatesTo)) {

			throw new DocuSignException(Label.UndefinedRelationship);
		}

		SObjectType relatesToType = relationship.getType();
		List<Recipient> result = null;
		for (RecipientResolver rr : RECIPIENT_RESOLVERS) {
			if (rr.canResolveRecipientType(relatesToType)) {
				result = rr.getRelatedRecipients(type, ids, relationship, filter);
				break;
			}
		}
		return result;
	}

	private static Recipient.SearchBehavior getSearchBehavior() {
		Recipient.SearchBehavior result = Recipient.SearchBehavior.DiscreteMatchBeginning;
		String sb = AccountSettings__c.getOrgDefaults().RecipientSearchBehavior__c;
		if (sb == 'CompoundMatchBeginning') {
			result = Recipient.SearchBehavior.CompoundMatchBeginning;
		} else if (sb == 'CompoundMatchExact') {
			result = Recipient.SearchBehavior.CompoundMatchExact;
		} else if (sb == 'CompoundMatchAny') {
			result = Recipient.SearchBehavior.CompoundMatchAny;
		} else if (sb == 'DiscreteMatchExact') {
			result = Recipient.SearchBehavior.DiscreteMatchExact;
		} else if (sb == 'DiscreteMatchAny') {
			result = Recipient.SearchBehavior.DiscreteMatchAny;
		}
		return result;
	}

	/**
	 * Searches for DocuSign envelope recipients from Salesforce source objects.
	 * <p>
	 * By default, the Salesforce <code>Contact</code>, <code>Lead</code>, and <code>User</code> types are supported.
	 * More types may be supported via plugins.
	 * <p>
	 * Search behavior is defined and stored in account settings. See <code>dfsle.Recipient.SearchBehavior</code> and
	 * <code>dfsle.AccountService.Settings</code> for more details.
	 *
	 * @param type The Salesforce object type.
	 * @param firstName The first name to match.
	 * @param lastName The last name to match. Ignored for compound search behaviors.
	 *
	 * @return A list of envelope recipients.
	 * @see Recipient.SearchBehavior for more details on search options.
	 */
	global static List<Recipient> searchRecipients(final SObjectType type, final String firstName,
		final String lastName) {

		if (type == null) throw new DocuSignException(Label.UndefinedType);

		List<Recipient> result = null;
		for (RecipientResolver rr : RECIPIENT_RESOLVERS) {
			if (rr.canSearchRecipients(type)) {
				result = rr.searchRecipients(type, firstName, lastName, getSearchBehavior());
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

	/**
	 * Retrieves a list of default recipient roles. These map to automatic anchor tags. For example, role 1 will map to
	 * <code>\s1\</code>, <code>\d1\</code>, etc.
	 *
	 * @return A list of default recipient roles.
	 */
	global static List<Recipient.Role> getDefaultRoles() {
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

		if (result == null && String.isNotBlank(roleName)) {
			result = new Recipient.Role(roleName);
		}

		return result;
	}

	private static Boolean isRoleAvailable(
		final String roleName,
		final Set<String> rolesInUse) {

		return String.isNotBlank(roleName)
			&& (rolesInUse == null
			|| !rolesInUse.contains(roleName));
	}

	@TestVisible
	private static MergeResult mergeRole(
		final Recipient recipient,
		final Set<String> rolesInUse) {

		Recipient.Role role = null;

		if (recipient != null
			&& recipient.role != null
			&& isRoleAvailable(recipient.role.name, rolesInUse)) {
			// either already added to envelope with a valid role or not in use
			role = resolveRole(recipient.role.name);
		} else if (recipient.role == null || String.isBlank(recipient.role.name)) {
			// Use next available default role
			for (Recipient.Role r : getDefaultRoles()) {
				if (r != null && isRoleAvailable(r.name, rolesInUse)) {
					role = r;
					break;
				}
			}
		}

		return new MergeResult(recipient.withRole(role), role != null);
	}

	@TestVisible
	private static List<Recipient> mergeDefaultSettings(
		final List<Recipient> recipients,
		final Set<String> rolesInUse) {

		if (recipients == null) {
			LOG.warn('Skipping default settings merge because recipients are null');
			return new List<Recipient>();
		}

		Set<String> roles = rolesInUse == null ? new Set<String>() : rolesInUse;
		List<Recipient> mergedRecipients = new List<Recipient>();
		for (Recipient r : recipients) {
			if (r == null) throw new DocuSignException(Label.UndefinedRecipient);

			MergeResult mr = mergeRole(r, roles);
			roles = markRoleUsed(mr, roles);
			if (!mr.isMerged || mr.recipient.role == null) {
				LOG.warn('Did not merge recipient \'' + mr.recipient.id + '\' role \''
					+ (mr.recipient.role != null ? mr.recipient.role.name : '')
					+ '\' because there were no available roles left');
			}
			mergedRecipients.add(mr.recipient);
		}
		return mergedRecipients;
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

	/**
	 * Prepares recipients for sending.
	 *
	 * @param recipients The recipients to prepare.
	 *
	 * @return The recipients with appropriate custom or default values.
	 */
	public static List<Recipient> prepareRecipients(final List<Recipient> recipients) {
		if (Collection.isEmpty(recipients)) throw new DocuSignException(Label.UndefinedRecipient);

		return mergeUserTags(mergeDefaultSettings(recipients, new Set<String>()));
	}

	/**
	 * Adds one or more recipients to a DocuSign envelope.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelopeId The envelope ID.
	 * @param recipients The recipients to add.
	 *
	 * @return The updated envelope recipients.
	 */
	public static List<Recipient> addEnvelopeRecipients(
		final Id envelopeId,
		final List<Recipient> recipients) {

		Permissions.verifyIsOwner(envelopeId);

		if (envelopeId == null) throw new DocuSignException(Label.UndefinedEnvelope);
		if (Collection.isEmpty(recipients)) throw new DocuSignException(Label.UndefinedRecipient);

		return DB.insertRecipients(envelopeId, recipients);
	}

	/**
	 * Adds recipients to one or more DocuSign envelopes. This method is called during envelope bulk insert.
	 *
	 * @param recipients A map of envelope IDs to recipients.
	 *
	 * @return The added map of envelope IDs to recipients.
	 */
	public static Map<Id, List<Recipient>> addEnvelopeRecipients(final Map<Id, List<Recipient>> recipients) {
		if (Collection.isEmpty(recipients)) return new Map<Id, List<Recipient>>();

		Permissions.verifyIsOwner(recipients.keySet());

		return DB.insertRecipients(recipients);
	}

	/**
	 * Updates a DocuSign envelope's recipients. Recipients may be deleted or upserted by this method.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelopeId The envelope ID.
	 * @param originalRecipients The original list of recipients.
	 * @param updatedRecipients The new list of recipients.
	 *
	 * @return The updated envelope recipients.
	 */
	public static List<Recipient> updateEnvelopeRecipients(
		final Id envelopeId,
		final List<Recipient> originalRecipients,
		final List<Recipient> updatedRecipients) {

		Permissions.verifyIsOwner(envelopeId);

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

	/**
	 * Retrieves a list of DocuSign envelope recipients associated with a Salesforce source entity.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set.
	 * <p>
	 * <em>This method is intended for DocuSign internal use only.</em>
	 *
	 * @param source The Salesforce source entity.
	 * @param defaultEmailSettings The default email localization.
	 *
	 * @return A list of envelope recipients.
	 */
	public static List<Recipient> resolveSourceRecipients(
		final Entity source,
		final Recipient.EmailSettings defaultEmailSettings) {

		Permissions.verifyIsDocuSignUser();

		if (source == null) return null;

		List<Recipient> result = getRecipients(source.type, new Set<Id> { source.id });
		if (result != null && defaultEmailSettings != null) {
			for (Integer i = 0; i < result.size(); i++) {
				result[i] = result[i].withEmailSettings(defaultEmailSettings);
			}
		}
		return result;
	}
}
