/**
 * Representation of a DocuSign Agreement HistoryItem.
 */
public class AgreementHistoryItem {

	@TestVisible
	public enum Action {
		DocumentImportedFromSalesforce,
		DocumentExportedToSalesforce,
		TitleChanged,
		ExternalReviewInitiated,
		ExternalReviewCompletedDocumentAndComments,
		ExternalReviewCompletedCheckoutCancelled,
		ExternalReviewCompletedDocumentCheckin,
		ExternalReviewCancelled,
		ExternalReviewCompletedInternally,
		ExternalReviewErrored,
		ApprovalCheckout,
		WorkflowApproved,
		WorkflowRejected,
		ApprovalCheckoutCanceled,
		DocumentCheckIn
	}

	public class Actor {
		public String fullName;
		public String emailAddress;
		public String accountUrl;

		public Actor(
			final String fullName,
			final String emailAddress,
			final String accountUrl) {

			this.fullName = fullName;
			this.emailAddress = emailAddress;
			this.accountUrl = accountUrl;
		}
	}

	@AuraEnabled
	public AgreementHistoryItem.Action historyItemType;

	@AuraEnabled
	public String currentUserEmail;

	@AuraEnabled
	public Datetime historyDate;

	@AuraEnabled
	public String subject;

	@AuraEnabled
	public String message;

	@AuraEnabled
	public String documentName;

	@AuraEnabled
	public AgreementHistoryItem.Actor actor;

	public List<AgreementHistoryItem.Actor> recipients;

	public AgreementHistoryItem (
		final AgreementHistoryItem.Action historyItemType,
		final String currentUserEmail,
		final Datetime historyDate,
		final String subject,
		final String message,
		final String documentName,
		final AgreementHistoryItem.Actor actor,
		final List<AgreementHistoryItem.Actor> recipients
	) {
		this.historyItemType = historyItemType;
		this.currentUserEmail = currentUserEmail;
		this.historyDate = historyDate;
		this.subject = subject;
		this.message = message;
		this.documentName = documentName;
		this.actor = actor;
		this.recipients = recipients;
	}

}