/**
 * Representation of a Action type in History items from SpringCM apis.
 */
public class HistoryItemAction {
/**
Action Type for New document created
 */
	public static final String DOCUMENT_IMPORTED_FROM_SALESFORCE = 'DocumentImportedFromSalesforce';
/**
Action Type for Document completed
 */
	public static final String DOCUMENT_EXPORTED_TO_SALESFORCE = 'DocumentExportedToSalesforce';
/**
Action Type for Rename a document
 */
	public static final String DOCUMENT_RENAMED = 'TitleChanged';
/**
Action Type for Sent for review
 */
	public static final String EXTERNAL_REVIEW_INITIATED = 'ExternalReviewInitiated';
/**
Action Type for Reviewed - new versions and comments
 */
	public static final String EXTERNAL_REVIEW_COMPLETED_DOCUMENT_AND_COMMENTS = 'ExternalReviewCompletedDocumentAndComments';
/**
Action Type for Reviewed - just comments
 */
	public static final String EXTERNAL_REVIEW_COMPLETED_CHECKOUT_CANCELLED = 'ExternalReviewCompletedCheckoutCancelled';
/**
Action Type for Reviewed - neither new version nor comments
 */
	public static final String EXTERNAL_REVIEW_COMPLETED_DOCUMENT_CHECK_IN = 'ExternalReviewCompletedDocumentCheckin';
/**
Action Type for Review canceled
 */
	public static final String EXTERNAL_REVIEW_CANCELLED = 'ExternalReviewCancelled';
/**
Action Type for Review completed by SOMEONE internally
 */
	public static final String EXTERNAL_REVIEW_COMPLETED_INTERNALLY = 'ExternalReviewCompletedInternally';
/**
Action Type for Error sending review
 */
	public static final String EXTERNAL_REVIEW_ERRORED = 'ExternalReviewErrored';
/**
Action Type for Sent for Approval
 */
	public static final String APPROVAL_CHECKOUT = 'ApprovalCheckout';
/**
Action Type for Approved workflow
 */
	public static final String WORKFLOW_APPROVED = 'WorkflowApproved';
/**
Action Type for Rejected workflow
 */
	public static final String WORKFLOW_REJECTED = 'WorkflowRejected';
/**
Action Type for Approval canceled
 */
	public static final String APPROVAL_CHECKOUT_CANCELED = 'ApprovalCheckoutCanceled';
	/**
Action Type for New version uploaded
 */
	public static final String DOCUMENT_CHECK_IN = 'DocumentCheckIn';

}