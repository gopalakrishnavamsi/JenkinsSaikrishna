public with sharing class RecipientService {

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

	public static Recipient convert(final Recipient__c r) {
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
}
