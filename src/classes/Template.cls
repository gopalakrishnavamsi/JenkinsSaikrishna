/**
 * Representation of a DocuSign template.
 */
public class Template {
	/**
	 * The DocuSign template ID.
	 */
	@AuraEnabled
	public UUID id { get; private set; }
	/**
	 * The DocuSign template name.
	 */
	@AuraEnabled
	public String name { get; private set; }
	/**
	 * The DocuSign template custom fields.
	 */
	@AuraEnabled
	public List<CustomField> customFields { get; private set; }
	/**
	 * The reminder and expiration settings for the template.
	 */
	@AuraEnabled
	public Notifications notifications { get; private set; }
	/**
	 * The subject of the email recipients receive.
	 */
	@AuraEnabled
	public String emailSubject { get; private set; }
	/**
	 * The message of the email recipients receive. This is contained within the standard DocuSign email body.
	 */
	@AuraEnabled
	public String emailMessage { get; private set; }
	/**
	 * The DocuSign template recipients.
	 */
	@AuraEnabled
	public List<Recipient> recipients { get; private set; }
	/**
	 * The date and time when the DocuSign template was last modified.
	 */
	@AuraEnabled
	public Datetime lastModified { get; private set; }

	/**
	 * Constructs a DocuSign template.
	 *
	 * @param id The DocuSign template ID.
	 * @param name The DocuSign template name.
	 * @param customFields The DocuSign template custom fields.
	 * @param notifications The reminder and expiration settings for the template.
	 * @param emailSubject The subject of the email recipients receive.
	 * @param emailMessage The message of the email recipients receive. This is contained within the standard DocuSign email body.
	 * @param recipients The DocuSign template recipients.
	 * @param lastModified The date and time when the DocuSign template was last modified.
	 */
	public Template(
		final UUID id,
		final String name,
		final List<CustomField> customFields,
		final Notifications notifications,
		final String emailSubject,
		final String emailMessage,
		final List<Recipient> recipients,
		final Datetime lastModified) {

		this.id = id;
		this.name = name;
		this.customFields = customFields;
		this.notifications = notifications;
		this.emailSubject = emailSubject;
		this.emailMessage = emailMessage;
		this.recipients = recipients;
		this.lastModified = lastModified;
	}
}
