/**
 * Account-level DocuSign for Salesforce settings.
 */
public with sharing class AccountSettings {

	private static AccountSettings self = null;
	private static final Integer DEFAULT_CALLOUT_TIMEOUT = 60000;

	/**
	 * Whether to use the logged-in DocuSign administrator for senders who are not members of the DocuSign account.
	 */
	@AuraEnabled
	public Boolean useSystemSender { get; private set; }
	/**
	 * Apex callout timeout. The default is 90 seconds.
	 */
	@AuraEnabled
	public Integer calloutTimeout { get; private set; }
	/**
	 * Salesforce entity resolvers. May be extended to resolve Salesforce objects unknown to DocuSign for Salesforce.
	 */
	@AuraEnabled
	public List<String> entityResolvers { get; private set; }
	/**
	 * DocuSign envelope document resolvers. May be extended to resolve Salesforce document types unknown to
	 * DocuSign for Salesforce.
	 */
	@AuraEnabled
	public List<String> documentResolvers { get; private set; }
	/**
	 * DocuSign envelope recipient resolvers. May be extended to resolve Salesforce recipient types unknown to
	 * DocuSign for Salesforce.
	 */
	@AuraEnabled
	public List<String> recipientResolvers { get; private set; }
	/**
	 * How to perform recipient searches. The ideal method is depended upon the subscriber org (number of contacts,
	 * platform encryption). The default search behavior is <code>DiscreteMatchBeginning</code> which allows partial
	 * matches on the beginning of first and last names. This is an efficient option for most subscriber orgs
	 * and can support deterministic platform encryption of these fields.
	 *
	 * @see Recipient.SearchBehavior for more details on search options.
	 */
	@AuraEnabled
	public String recipientSearchBehavior { get; private set; }

	public AccountSettings(
		final Boolean useSystemSender,
		final Integer calloutTimeout,
		final List<String> entityResolvers,
		final List<String> documentResolvers,
		final List<String> recipientResolvers,
		final String recipientSearchBehavior) {

		this.useSystemSender = useSystemSender;
		this.calloutTimeout = calloutTimeout;
		this.entityResolvers = entityResolvers;
		this.documentResolvers = documentResolvers;
		this.recipientResolvers = recipientResolvers;
		this.recipientSearchBehavior = recipientSearchBehavior;
	}

	public static AccountSettings getInstance() {
		if (self == null) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			self = new AccountSettings(
				s.UseSystemSender__c == true,
				Integer.valueOf(s.CalloutTimeout__c),
				String.isBlank(s.EntityResolvers__c) ? new List<String>() : s.EntityResolvers__c.split(','),
				String.isBlank(s.DocumentResolvers__c) ? new List<String>() : s.DocumentResolvers__c.split(','),
				String.isBlank(s.RecipientResolvers__c) ? new List<String>() : s.RecipientResolvers__c.split(','),
				s.RecipientSearchBehavior__c
			);
		}
		return self;
	}

	public static AccountSettings save(final AccountSettings settings) {
		if (settings == null) throw new DocuSignException(Label.UndefinedArgument);

		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.UseSystemSender__c = settings.useSystemSender == true;
		s.CalloutTimeout__c = settings.calloutTimeout == null ? DEFAULT_CALLOUT_TIMEOUT : settings.calloutTimeout;
		s.EntityResolvers__c = Collection.mkString(settings.entityResolvers, ',');
		s.DocumentResolvers__c = Collection.mkString(settings.documentResolvers, ',');
		s.RecipientResolvers__c = Collection.mkString(settings.recipientResolvers, ',');
		s.RecipientSearchBehavior__c = settings.recipientSearchBehavior;
		upsert s;

		self = null;
		return getInstance();
	}
}
