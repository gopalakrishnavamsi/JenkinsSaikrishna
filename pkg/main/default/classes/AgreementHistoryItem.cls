/**
 * Representation of a DocuSign Agreement HistoryItem.
 */
public class AgreementHistoryItem {
	public static final String DocumentImportFromSalesforce = 'DocumentImportFromSalesforce';
	public static final String DocumentExportedToSalesforce = 'DocumentExportedToSalesforce';
	public static final String DocumentAdded = 'DocumentAdded';
	public static final String TitleChanged = 'TitleChanged';
	public static final String ExternalReviewInitiated = 'ExternalReviewInitiated';
	public static final String ExternalReviewCompletedDocumentAndComments = 'ExternalReviewCompletedDocumentAndComments';
	public static final String ExternalReviewCompletedCheckoutCancelled = 'ExternalReviewCompletedCheckoutCancelled';
	public static final String ExternalReviewCompletedDocumentCheckin = 'ExternalReviewCompletedDocumentCheckin';
	public static final String ExternalReviewCancelled = 'ExternalReviewCancelled';
	public static final String ExternalReviewCompletedInternally = 'ExternalReviewCompletedInternally';
	public static final String ExternalReviewErrored = 'ExternalReviewErrored';
	public static final String ApprovalCheckout = 'ApprovalCheckout';
	public static final String WorkflowApproved = 'WorkflowApproved';
	public static final String WorkflowRejected = 'WorkflowRejected';
	public static final String ApprovalCheckoutCanceled = 'ApprovalCheckoutCanceled';
	public static final String DocumentCheckIn = 'DocumentCheckIn';

	public class Actor {

		@AuraEnabled
		public String fullName;

		@AuraEnabled
		public String email;

		@AuraEnabled
		public String accountUrl;

		public Actor(
			final String fullName,
			final String email,
			final String accountUrl) {

			this.fullName = fullName;
			this.email = email;
			this.accountUrl = accountUrl;
		}
	}

	@AuraEnabled
	public String historyItemType;

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
	public String documentVersion; //required to display Document version after new Document checkin

	@AuraEnabled
	public String originalName; //indicates name before renaming the agreement.

	@AuraEnabled
	public String name; // indicates name after renaming the agreement

	@AuraEnabled
	public AgreementHistoryItem.Actor actor;

	@AuraEnabled
	public List<AgreementHistoryItem.Actor> recipients;

	public AgreementHistoryItem (
		final String historyItemType,
		final String currentUserEmail,
		final Datetime historyDate,
		final String subject,
		final String message,
		final String documentName,
		final String documentVersion,
		final String originalName,
		final String name,
		final AgreementHistoryItem.Actor actor,
		final List<AgreementHistoryItem.Actor> recipients
	) {
		this.historyItemType = historyItemType;
		this.currentUserEmail = currentUserEmail;
		this.historyDate = historyDate;
		this.subject = subject;
		this.message = message;
		this.documentName = documentName;
		this.documentVersion = documentVersion;
		this.originalName = originalName;
		this.name = name;
		this.actor = actor;
		this.recipients = recipients;
	}

}