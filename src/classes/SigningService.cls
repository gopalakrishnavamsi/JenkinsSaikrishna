/**
 * Encapsulates signing-related operations.
 */
public with sharing class SigningService {

	@TestVisible
	private static final SigningService.Database DB = new SigningService.Database();
	private static final LoggerService LOG = LoggerService.getInstance();
	@TestVisible
	private static final Set<String> SIGN_NOW_TYPES = new Set<String> {
		Recipient.TYPE_SIGNER, Recipient.TYPE_IN_PERSON_SIGNER
	};

	@TestVisible
	private with sharing class Database {

		public Boolean completeSignNow(final Id recipientId) {
			Permissions.verifyIsUpdateable(Recipient__c.getSObjectType(), new List<String> { 'SignNow__c' });

			Boolean result = false;
			if (recipientId != null) {
				update new Recipient__c(
					Id = recipientId,
					SignNow__c = false);
				result = true;
			}
			return result;
		}
	}

	@TestVisible
	private static Recipient getNextSignNowRecipient(final List<Recipient> recipients, final String name,
		final String email, final Boolean checkFirstRecipientOnly) {

		Recipient result = null;
		if (Collection.isNotEmpty(recipients)) {
			if (checkFirstRecipientOnly) {
				result = recipients[0].signNow ? recipients[0] : null;
			} else {
				Boolean allowSequentialSignNow = EnvelopeSettings__c.getOrgDefaults().AllowSequentialSignNow__c;
				Boolean isFirst = true;
				for (Recipient r : recipients) {
					if (r.signNow == null ? false : r.signNow
						&& r.id != null
						&& (isFirst || allowSequentialSignNow)
						&& ((r.name == name && r.email == email) || (r.hostName == name && r.hostEmail == email))
						&& r.sequence > 0
						&& SIGN_NOW_TYPES.contains(r.type)) {

						result = r;
						break;
					}
					isFirst = false;
				}
			}
		}
		return result;
	}

	/**
	 * Determines whether the next DocuSign envelope recipient should sign now.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelope The DocuSign envelope.
	 *
	 * @return <code>true</code> if the next recipient should sign now, <code>false</code> otherwise.
	 */
	public static Boolean shouldSignNow(final Envelope envelope) {
		if (envelope != null) Permissions.verifyIsOwner(envelope.id);

		Boolean result = false;
		if (envelope != null && Collection.isNotEmpty(envelope.recipients)) {
			for (Recipient r : envelope.recipients) {
				// Return true if any recipient is flagged to sign now.
				if (r.signNow == true) {
					result = true;
					break;
				}
			}
		}
		return result;
	}

	/**
	 * Retrieves the signing URL for the next 'sign now' signer, either in-person or the current user as signer.
	 * <p>
	 * The caller must be the owner of the envelope.
	 *
	 * @param envelope The DocuSign envelope.
	 * @param returnUrl Where to redirect after signing.
	 * @param checkFirstRecipientOnly Whether to check only the first recipient or all recipients.
	 *
	 * @return The signing URL.
	 */
	public static Url getSigningUrl(final Envelope envelope, final Url returnUrl, final Boolean checkFirstRecipientOnly) {
		if (envelope != null) Permissions.verifyIsOwner(envelope.id);

		Url result = null;
		if (envelope != null && envelope.docuSignId != null) {
			String name = UserInfo.getName();
			String email = UserInfo.getUserEmail();
			Recipient snr = getNextSignNowRecipient(envelope.recipients, name, email, checkFirstRecipientOnly);

			if (snr != null && snr.sequence != null) {
				try {
					result = EnvelopeAPI.getInstance().getRecipientViewUrl(
						envelope.docuSignId,
						returnUrl,
						email,
						name,
						snr.sequence);
				} finally {
					// Mark sign now as false in DB so we don't get stuck in a loop with a bad signer.
					DB.completeSignNow(snr.withSignNow(false).id);
				}
			}
		}
		return result;
	}
}
