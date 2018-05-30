/**
 * Representation of a DocuSign template.
 */
public class Template {
	/**
	 * The DocuSign template ID.
	 */
	public UUID id { get; private set; }
	/**
	 * The DocuSign template name.
	 */
	public String name { get; private set; }
	/**
	 * The DocuSign template custom fields.
	 */
	public List<CustomField> customFields { get; private set; }
	/**
	 * The reminder and expiration settings for the envelope.
	 */
	public Envelope.Notifications notifications { get; private set; }
	/**
	 * The subject of the email recipients receive.
	 */
	public String emailSubject { get; private set; }
	/**
	 * The message of the email recipients receive. This is contained within the standard DocuSign email body.
	 */
	public String emailMessage { get; private set; }
	/**
	 * The DocuSign template recipients.
	 */
	public List<Recipient> recipients { get; private set; }

	/**
	 * Constructs a DocuSign template.
	 *
	 * @param id The DocuSign template ID.
	 * @param name The DocuSign template name.
	 * @param customFields The DocuSign template custom fields.
	 * @param notifications The reminder and expiration settings for the envelope.
	 * @param emailSubject The subject of the email recipients receive.
	 * @param emailMessage The message of the email recipients receive. This is contained within the standard DocuSign email body.
	 * @param recipients The DocuSign template recipients.
	 */
	public Template(
		final UUID id,
		final String name,
		final List<CustomField> customFields,
		final Envelope.Notifications notifications,
		final String emailSubject,
		final String emailMessage,
		final List<Recipient> recipients) {

		this.id = id;
		this.name = name;
		this.customFields = customFields;
		this.notifications = notifications;
		this.emailSubject = emailSubject;
		this.emailMessage = emailMessage;
		this.recipients = recipients;
	}
}
