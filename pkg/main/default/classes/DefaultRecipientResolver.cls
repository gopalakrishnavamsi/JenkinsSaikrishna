public with sharing class DefaultRecipientResolver implements RecipientResolver {

	private static final SObjectType TYPE_ACCOUNT = Schema.Account.getSObjectType();
	private static final SObjectType TYPE_CASE = Case.getSObjectType();
	private static final SObjectType TYPE_CASE_CONTACT_ROLE = CaseContactRole.getSObjectType();
	private static final SObjectType TYPE_CONTACT = Contact.getSObjectType();
	private static final SObjectType TYPE_LEAD = Lead.getSObjectType();
	private static final SObjectType TYPE_OPPORTUNITY = Opportunity.getSObjectType();
	private static final SObjectType TYPE_OPPORTUNITY_CONTACT_ROLE = OpportunityContactRole.getSObjectType();
	private static final SObjectType TYPE_USER = User.getSObjectType();
	private static final Integer DEFAULT_LIMIT = 10;

	private static final Set<SObjectType> RESOLVABLE_TYPES = new Set<SObjectType> {
		TYPE_CONTACT, TYPE_LEAD, TYPE_USER,
		TYPE_OPPORTUNITY_CONTACT_ROLE, TYPE_CASE_CONTACT_ROLE
	};

	private static final Set<SObjectType> DEFAULT_SOURCES = new Set<SObjectType> {
		TYPE_ACCOUNT, TYPE_CASE, TYPE_CONTACT, TYPE_LEAD, TYPE_OPPORTUNITY, TYPE_USER
	};

	private static final Set<SObjectType> SEARCHABLE_TYPES = new Set<SObjectType> {
		TYPE_CONTACT, TYPE_LEAD, TYPE_USER
	};

	static {
		// AccountTeamMember and OpportunityTeamMember SObjects are only available if the admin has enabled
		// Account or Opportunity Teams, so we cannot have a hard reference to these types.
		if (Salesforce.isValidSObject('AccountTeamMember')) {
			RESOLVABLE_TYPES.add(Salesforce.getSObjectType('AccountTeamMember'));
		}
		if (Salesforce.isValidSObject('OpportunityTeamMember')) {
			RESOLVABLE_TYPES.add(Salesforce.getSObjectType('OpportunityTeamMember'));
		}
	}

	public Boolean canResolveRecipientType(final SObjectType type) {
		return type != null && RESOLVABLE_TYPES.contains(type);
	}

	public Boolean canResolveRecipientSource(final SObjectType type) {
		return type != null && DEFAULT_SOURCES.contains(type);
	}

	public Boolean canSearchRecipients(final SObjectType type) {
		return type != null && SEARCHABLE_TYPES.contains(type);
	}

	private static Object getValue(
		final SObject obj,
		final String field) {

		return obj == null || String.isBlank(field) || !obj.isSet(field) ? null : obj.get(field);
	}

	private static SObject getSObject(
		final SObject obj,
		final String field,
		final String idField) {

		return obj == null
			|| String.isBlank(field)
			|| (String.isBlank(idField) && !obj.isSet(field))
			|| !obj.isSet(idField) ? null : obj.getSObject(field);
	}

	private static Recipient convert(
		final SObject obj,
		final String role,
		final Entity parent) {

		if (obj == null) return null;

		String name = (String)getValue(obj, 'Name');
		String mobilePhone = (String)getValue(obj, 'MobilePhone');
		return Recipient.fromSource(
			name,
			(String)getValue(obj, 'Email'),
			String.isBlank(mobilePhone) ? (String)getValue(obj, 'Phone') : mobilePhone,
			role,
			new Entity(
				obj.Id,
				name,
				parent));
	}

	private static List<Recipient> convert(final List<SObject> objs) {
		List<Recipient> result = new List<Recipient>();
		if (objs != null) {
			for (SObject obj : objs) {
				if (obj != null) result.add(convert(obj, null, null));
			}
		}
		return result;
	}

	private static Recipient convert(final Contact contact) {
		if (contact == null) return null;

		Schema.Account account = (Schema.Account)getSObject(contact, 'Account', 'AccountId');
		return convert(
			contact,
			null,
			account == null ? null : new Entity(
				account.Id,
				account.Name,
				null));
	}

	private static List<Recipient> convert(final List<Contact> contacts) {
		List<Recipient> result = new List<Recipient>();
		if (contacts != null) {
			for (Contact contact : contacts) {
				if (contact != null) result.add(convert(contact));
			}
		}
		return result;
	}

	private static List<Recipient> getAccountRecipients(final Set<Id> accountIds) {
		Permissions.verifyIsQueryable(TYPE_CONTACT, new List<String> { 'Name', 'Email' });
		Permissions.verifyIsQueryable(TYPE_ACCOUNT);

		if (Collection.isEmpty(accountIds)) return new List<Recipient>();

		return convert((List<Contact>)Security.stripInaccessible(AccessType.READABLE, [
			SELECT Id, Name, Email, Phone, MobilePhone, Account.Id, Account.Name
			FROM Contact
			WHERE AccountId IN :accountIds
			ORDER BY CreatedDate
		]).getRecords());
	}

	private static List<Recipient> getCaseRecipients(final Set<Id> caseIds) {
		Permissions.verifyIsQueryable(TYPE_CONTACT, new List<String> { 'Name', 'Email' });
		Permissions.verifyIsQueryable(TYPE_CASE);

		List<Recipient> result = new List<Recipient>();
		if (Collection.isNotEmpty(caseIds)) {
			for (Case c : (List<Case>)Security.stripInaccessible(AccessType.READABLE, [
				SELECT Id, CaseNumber, Contact.Id, Contact.Name, Contact.Email, Contact.Phone, Contact.MobilePhone
				FROM Case
				WHERE Id IN :caseIds
				ORDER BY CreatedDate
			]).getRecords()) {
				if (c != null && c.isSet('ContactId')) {
					result.add(convert(
						c.Contact,
						null,
						new Entity(
							c.Id,
							(String)getValue(c, 'CaseNumber'),
							null)));
				}
			}
		}
		return result;
	}

	private static List<Recipient> getContactRecipients(final Set<Id> contactIds) {
		Permissions.verifyIsQueryable(TYPE_CONTACT, new List<String> { 'Name', 'Email' });
		Permissions.verifyIsQueryable(TYPE_ACCOUNT);

		if (Collection.isEmpty(contactIds)) return new List<Recipient>();

		return convert((List<Contact>)Security.stripInaccessible(AccessType.READABLE, [
			SELECT Id, Name, Email, Phone, MobilePhone, Account.Id, Account.Name
			FROM Contact
			WHERE Id IN :contactIds
			ORDER BY CreatedDate
		]).getRecords());
	}

	private static List<Recipient> getLeadRecipients(final Set<Id> leadIds) {
		Permissions.verifyIsQueryable(TYPE_LEAD, new List<String> { 'Name', 'Email' });

		if (Collection.isEmpty(leadIds)) return new List<Recipient>();

		return convert(Security.stripInaccessible(AccessType.READABLE, [
			SELECT Id, Name, Email, Phone, MobilePhone
			FROM Lead
			WHERE Id IN :leadIds
			ORDER BY CreatedDate
		]).getRecords());
	}

	private static List<Recipient> getOpportunityRecipients(final Set<Id> opportunityIds) {
		Permissions.verifyIsQueryable(TYPE_CONTACT, new List<String> {
			'Name', 'Email'
		});
		Permissions.verifyIsQueryable(TYPE_OPPORTUNITY_CONTACT_ROLE);
		Permissions.verifyIsQueryable(TYPE_ACCOUNT);

		List<Recipient> result = new List<Recipient>();
		if (Collection.isNotEmpty(opportunityIds)) {
			for (OpportunityContactRole ocr : (List<OpportunityContactRole>)Security.stripInaccessible(
				AccessType.READABLE, [
				SELECT
					Id,
					Contact.Id,
					Contact.Name,
					Contact.Email,
					Contact.Phone,
					Contact.MobilePhone,
					Opportunity.Account.Id,
					Opportunity.Account.Name,
					Role
				FROM OpportunityContactRole
				WHERE OpportunityId IN :opportunityIds
				AND Contact.Id != NULL
				ORDER BY CreatedDate
			]).getRecords()) {
				if (ocr != null && ocr.isSet('ContactId')) {
					Schema.Account account = ocr.isSet('OpportunityId')
						? (Schema.Account)getSObject(ocr.Opportunity, 'Account', 'AccountId') : null;
					result.add(convert(
						ocr.Contact,
						(String)getValue(ocr, 'Role'),
						account == null ? null : new Entity(
							account.Id,
							account.Name,
							null)));
				}
			}
		}
		return result;
	}

	private static List<Recipient> getUserRecipients(final Set<Id> userIds) {
		Permissions.verifyIsQueryable(TYPE_USER, new List<String> {
			'Name', 'Email'
		});

		if (Collection.isEmpty(userIds)) return new List<Recipient>();

		return convert(Security.stripInaccessible(AccessType.READABLE, [
			SELECT Id, Name, Email, Phone, MobilePhone
			FROM User
			WHERE Id IN :userIds
			ORDER BY CreatedDate
		]).getRecords());
	}

	public List<Recipient> getSourceRecipients(
		final SObjectType type,
		final Set<Id> ids) {

		if (type == null) throw new DocuSignException(Label.UndefinedType);

		List<Recipient> result = null;
		if (type == TYPE_ACCOUNT) {
			result = getAccountRecipients(ids);
		} else if (type == TYPE_CASE) {
			result = getCaseRecipients(ids);
		} else if (type == TYPE_CONTACT) {
			result = getContactRecipients(ids);
		} else if (type == TYPE_LEAD) {
			result = getLeadRecipients(ids);
		} else if (type == TYPE_OPPORTUNITY) {
			result = getOpportunityRecipients(ids);
		} else if (type == TYPE_USER) {
			result = getUserRecipients(ids);
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveRecipientSource_1,
				new List<String> { String.valueOf(type) }));
		}
		return result;
	}

	@TestVisible
	private static List<SObject> executeQuery(
		final SObjectType type,
		final List<String> fields,
		final Set<Id> ids,
		final Query.Relationship relationship,
		final Query.Filter filter) {

		Integer size = ids == null ? 0 : ids.size();
		Integer maximumRecords = filter != null && filter.maximumRecords > 0
			? filter.maximumRecords
			: (relationship.isLookup ? size : DEFAULT_LIMIT);
		String query = relationship.isLookup
			? String.format(
				'SELECT {0} '
					+ 'FROM {1} '
					+ 'WHERE Id IN :ids{2} WITH SECURITY_ENFORCED '
					+ 'ORDER BY {3} '
					+ 'LIMIT :maximumRecords',
				new List<Object> {
					String.format('{0}.' + String.join(fields, ', {0}.'),
						new List<Object> { String.escapeSingleQuotes(relationship.name) }),
					type,
					filter == null || String.isBlank(filter.filterBy) ? '' : (' AND (' + filter.filterBy + ')'),
					filter == null || String.isBlank(filter.orderBy) ? 'CreatedDate ASC' : filter.orderBy
				})
			: String.format(
				'SELECT (SELECT {0} FROM {1}{2} ORDER BY {3} LIMIT :maximumRecords) '
					+ 'FROM {4} '
					+ 'WHERE Id IN :ids WITH SECURITY_ENFORCED '
					+ 'LIMIT :size',
				new List<Object> {
					String.join(fields, ', '),
					String.escapeSingleQuotes(relationship.name),
					filter == null || String.isBlank(filter.filterBy) ? '' : (' WHERE ' + filter.filterBy),
					filter == null || String.isBlank(filter.orderBy) ? 'CreatedDate ASC' : filter.orderBy,
					type
				});
		return Security.stripInaccessible(AccessType.READABLE, Database.query(query)).getRecords();
	}

	private static List<Recipient> getRelatedContacts(
		final SObjectType type,
		final Set<Id> ids,
		final Query.Relationship relationship,
		final Query.Filter filter) {

		// These must be queryable. Optional fields that are inaccessible are stripped out of the query results.
		Permissions.verifyIsQueryable(TYPE_CONTACT, new List<String> { 'Name', 'Email' });
		Permissions.verifyIsQueryable(TYPE_ACCOUNT);

		List<Recipient> result = new List<Recipient>();
		if (Collection.isNotEmpty(ids)) {
			for (SObject obj : executeQuery(
				type,
				new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone', 'Account.Id', 'Account.Name' },
				ids,
				relationship,
				filter)) {

				if (obj == null) continue;

				if (relationship.isLookup) {
					Contact contact = (Contact)obj.getSObject(relationship.name);
					if (contact != null) result.add(convert(contact));
				} else {
					for (Contact contact : (List<Contact>)obj.getSObjects(relationship.name)) {
						if (contact != null) result.add(convert(contact));
					}
				}
			}
		}
		return result;
	}

	private static List<Recipient> getRelatedLeads(
		final SObjectType type,
		final Set<Id> ids,
		final Query.Relationship relationship,
		final Query.Filter filter) {

		Permissions.verifyIsQueryable(TYPE_LEAD, new List<String> { 'Name', 'Email' });

		List<Recipient> result = new List<Recipient>();
		if (Collection.isNotEmpty(ids)) {
			for (SObject obj : executeQuery(
				type,
				new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' },
				ids,
				relationship,
				filter)) {

				if (obj == null) continue;

				if (relationship.isLookup) {
					result.add(convert(obj.getSObject(relationship.name), null, null));
				} else {
					result.addAll(convert(obj.getSObjects(relationship.name)));
				}
			}
		}
		return result;
	}

	private static List<Recipient> getRelatedUsers(
		final SObjectType type,
		final Set<Id> ids,
		final Query.Relationship relationship,
		final Query.Filter filter) {

		Permissions.verifyIsQueryable(TYPE_USER, new List<String> { 'Name', 'Email' });

		List<Recipient> result = new List<Recipient>();
		if (Collection.isNotEmpty(ids)) {
			for (SObject obj : executeQuery(
				type,
				new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' },
				ids,
				relationship,
				filter)) {

				if (obj == null) continue;

				if (relationship.isLookup) {
					result.add(convert(obj.getSObject(relationship.name), null, null));
				} else {
					result.addAll(convert(obj.getSObjects(relationship.name)));
				}
			}
		}
		return result;
	}

	private static List<Recipient> getRelatedContactRoles(
		final SObjectType type,
		final Set<Id> ids,
		final Query.Relationship relationship,
		final Query.Filter filter) {

		Permissions.verifyIsQueryable(TYPE_CONTACT, new List<String> { 'Name', 'Email' });
		Permissions.verifyIsQueryable(TYPE_ACCOUNT);

		List<Recipient> result = new List<Recipient>();
		if (Collection.isNotEmpty(ids)) {
			for (SObject obj : executeQuery(
				type,
				new List<String> {
					'Contact.Id', 'Contact.Name', 'Contact.Email', 'Contact.Phone', 'Contact.MobilePhone',
					'Contact.Account.Id', 'Contact.Account.Name', 'Role'
				},
				ids,
				relationship,
				filter)) {

				if (obj == null) continue;

				for (SObject contactRole : obj.getSObjects(relationship.name)) {
					if (contactRole == null) continue;

					Contact contact = (Contact)contactRole.getSObject('Contact');
					if (contact != null) {
						Schema.Account account = (Schema.Account)getSObject(contact, 'Account', 'AccountId');
						result.add(convert(
							contact,
							(String)contactRole.get('Role'),
							account == null ? null : new Entity(
								account.Id,
								account.Name,
								null)));
					}
				}
			}
		}
		return result;
	}

	private static List<Recipient> getRelatedTeamMembers(
		final SObjectType type,
		final Set<Id> ids,
		final Query.Relationship relationship,
		final Query.Filter filter) {

		Permissions.verifyIsQueryable(TYPE_USER, new List<String> { 'Name', 'Email' });

		List<Recipient> result = new List<Recipient>();
		if (Collection.isNotEmpty(ids)) {
			for (SObject obj : executeQuery(
				type,
				new List<String> {
					'User.Id', 'User.Name', 'User.Email', 'User.Phone', 'User.MobilePhone', 'TeamMemberRole'
				},
				ids,
				relationship,
				filter)) {

				if (obj == null) continue;

				for (SObject teamMember : obj.getSObjects(relationship.name)) {
					if (teamMember == null) continue;

					User user = (User)teamMember.getSObject('User');
					if (user != null) {
						result.add(convert(
							user,
							(String)teamMember.get('TeamMemberRole'),
							null));
					}
				}
			}
		}
		return result;
	}

	public List<Recipient> getRelatedRecipients(
		final SObjectType type,
		final Set<Id> ids,
		final Query.Relationship relationship,
		final Query.Filter filter) {

		if (type == null) throw new DocuSignException(Label.UndefinedType);
		if (relationship == null
			|| String.isBlank(relationship.name)
			|| String.isBlank(relationship.relatesTo)) {

			throw new DocuSignException(Label.UndefinedRelationship);
		}

		List<Recipient> result = null;
		switch on relationship.relatesTo {
			when 'Contact' {
				result = getRelatedContacts(type, ids, relationship, filter);
			} when 'Lead' {
				result = getRelatedLeads(type, ids, relationship, filter);
			} when 'User' {
				result = getRelatedUsers(type, ids, relationship, filter);
			} when 'OpportunityContactRole', 'CaseContactRole' {
				result = getRelatedContactRoles(type, ids, relationship, filter);
			} when 'AccountTeamMember', 'OpportunityTeamMember' {
				result = getRelatedTeamMembers(type, ids, relationship, filter);
			} when else {
				throw new DocuSignException(String.format(Label.CannotResolveRecipientSource_1,
					new List<Object> { relationship.relatesTo }));
			}
		}

		return result == null ? new List<Recipient>() : result;
	}

	/*=============================================================================================================
	 * READ BEFORE MODIFYING THE searchContacts, searchLeads, OR searchUsers METHODS:
	 * 1. Some Shield orgs encrypt names. Must use dynamic SOQL (Database.query) to avoid compilation issues.
	 * 2. Matching any part of string (%_%) is VERY inefficient and will be painfully slow or break on orgs with
	 * 	lots of records. Matching the first part (_%) is better.
	 =============================================================================================================*/

	private static String buildQuery(
		final String selector,
		final String firstName,
		final String lastName,
		final Boolean isCompound,
		final Boolean isExact) {

		String result = selector;
		List<String> filters = new List<String>();
		if (String.isNotBlank(firstName)) {
			if (isCompound && isExact) {
				filters.add(' Name = :firstName');
			} else if (isExact) {
				filters.add(' FirstName = :firstName');
			} else if (isCompound) {
				filters.add(' Name LIKE :firstName');
			} else {
				filters.add(' FirstName LIKE :firstName');
			}
		}
		if (!isCompound && String.isNotBlank(lastName)) {
			if (isExact) {
				filters.add(' LastName = :lastName');
			} else {
				filters.add(' LastName LIKE :lastName');
			}
		}
		if (Collection.isNotEmpty(filters)) {
			result += ' WHERE' + Collection.mkString(filters, ' AND ');
		}
		result += ' LIMIT 100';
		return result;
	}

	private static List<Recipient> searchContacts(
		final String firstName,
		final String lastName,
		final Boolean isCompound,
		final Boolean isExact) {

		Permissions.verifyIsQueryable(TYPE_CONTACT, new List<String> { 'Name', 'Email' });
		Permissions.verifyIsQueryable(TYPE_ACCOUNT);

		Boolean ic = isCompound && Permissions.isFilterable(TYPE_CONTACT, new List<String> { 'Name' }).isAuthorized;
		Boolean ie = isExact
			|| (ic && !Permissions.isUnencrypted(TYPE_CONTACT, new List<String> { 'Name' }).isAuthorized)
			|| (!ic && !Permissions.isUnencrypted(TYPE_CONTACT, new List<String> { 'FirstName', 'LastName' }).isAuthorized);
		String q = buildQuery('SELECT Id, Name, Email, Phone, MobilePhone, Account.Id, Account.Name FROM Contact',
			firstName, lastName, ic, ie);

		return convert((List<Contact>)Security.stripInaccessible(AccessType.READABLE,
			System.Database.query(q)).getRecords());
	}

	private static List<Recipient> searchLeads(
		final String firstName,
		final String lastName,
		final Boolean isCompound,
		final Boolean isExact) {

		Permissions.verifyIsQueryable(TYPE_LEAD, new List<String> { 'Name', 'Email' });

		Boolean ic = isCompound && Permissions.isFilterable(TYPE_LEAD, new List<String> { 'Name' }).isAuthorized;
		Boolean ie = isExact
			|| (ic && !Permissions.isUnencrypted(TYPE_LEAD, new List<String> { 'Name' }).isAuthorized)
			|| (!ic && !Permissions.isUnencrypted(TYPE_LEAD, new List<String> { 'FirstName', 'LastName' }).isAuthorized);
		String q = buildQuery('SELECT Id, Name, Email, Phone, MobilePhone FROM Lead',
			firstName, lastName, ic, ie);

		return convert(Security.stripInaccessible(AccessType.READABLE,
			System.Database.query(q)).getRecords());
	}

	private static List<Recipient> searchUsers(
		final String firstName,
		final String lastName,
		final Boolean isCompound,
		final Boolean isExact) {

		Permissions.verifyIsQueryable(TYPE_USER, new List<String> { 'Name', 'Email' });

		Boolean ic = isCompound && Permissions.isFilterable(TYPE_USER, new List<String> { 'Name' }).isAuthorized;
		Boolean ie = isExact
			|| (ic && !Permissions.isUnencrypted(TYPE_USER, new List<String> { 'Name' }).isAuthorized)
			|| (!ic && !Permissions.isUnencrypted(TYPE_USER, new List<String> { 'FirstName', 'LastName' }).isAuthorized);
		String q = buildQuery('SELECT Id, Name, Email, Phone, MobilePhone FROM User',
			firstName, lastName, ic, ie);

		return convert((List<User>)Security.stripInaccessible(AccessType.READABLE,
			System.Database.query(q)).getRecords());
	}

	private static String buildSearchTerm(
		final String name,
		final Recipient.SearchBehavior behavior) {

		String result = name == null ? null : name.trim();
		if (result != null) {
			if (behavior == Recipient.SearchBehavior.CompoundMatchExact
				|| behavior == Recipient.SearchBehavior.DiscreteMatchExact) {

				result = result;
			} else if (behavior == Recipient.SearchBehavior.CompoundMatchAny
				|| behavior == Recipient.SearchBehavior.DiscreteMatchAny) {

				result = '%' + result + '%'; // This is super inefficient, so avoid if possible.
			} else { // MatchBeginning
				result += '%';
			}
		}
		return result;
	}

	public List<Recipient> searchRecipients(
		final SObjectType type,
		final String firstName,
		final String lastName,
		final Recipient.SearchBehavior behavior) {

		if (type == null) throw new DocuSignException(Label.UndefinedType);

		List<Recipient> result = null;
		Boolean isCompound = behavior == null || behavior.name().startsWith('Compound');
		Boolean isExact = behavior != null && behavior.name().endsWith('Exact');
		if (type == TYPE_CONTACT) {
			result = searchContacts(buildSearchTerm(firstName, behavior), buildSearchTerm(lastName, behavior),
				isCompound, isExact);
		} else if (type == TYPE_LEAD) {
			result = searchLeads(buildSearchTerm(firstName, behavior), buildSearchTerm(lastName, behavior),
				isCompound, isExact);
		} else if (type == TYPE_USER) {
			result = searchUsers(buildSearchTerm(firstName, behavior), buildSearchTerm(lastName, behavior),
				isCompound, isExact);
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveRecipientSource_1,
				new List<String> { String.valueOf(type) }));
		}
		return result;
	}
}
