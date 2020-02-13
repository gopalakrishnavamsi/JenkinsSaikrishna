/**
 * Representation of a DocuSign Agreement status.
 */
public class AgreementStatus {

	public static final String NEW_AGREEMENT = 'NEW';
	public static final String NEW_VERSION = 'NEW VERSION';

	public static final String PENDING_REVIEW = 'PENDING REVIEW';
	public static final String REVIEWED = 'REVIEWED';
	public static final String REVIEW_CANCELLED = 'REVIEW CANCELLED';
	public static final String REVIEW_EXPIRED = 'REVIEW EXPIRED';

	public static final String PENDING_APPROVAL = 'PENDING APPROVAL';
	public static final String APPROVED = 'APPROVED';
	public static final String APPROVAL_CANCELLED = 'APPROVAL CANCELLED';
	public static final String COMPLETED = 'COMPLETED';

	public static final String REJECTED = 'REJECTED';
	public static final String SIGNED = 'SIGNED';
	public static final String SIGNATURE_CANCELLED = 'SIGNATURE CANCELLED';
	public static final String NO_STATUS = 'NO STATUS';
	public static final String PENDING_SIGNATURE = 'PENDING SIGNATURE';

	public static final String SYSTEM_ERROR = 'SYSTEM ERROR';

	public static final Set<String> VALID_STATUS = new Set<String> { NEW_AGREEMENT, NEW_VERSION, PENDING_REVIEW, REVIEWED,
		REVIEW_CANCELLED, REVIEW_EXPIRED, PENDING_APPROVAL, APPROVED, APPROVAL_CANCELLED, COMPLETED, REJECTED, SIGNED,
		SIGNATURE_CANCELLED, NO_STATUS, PENDING_SIGNATURE, SYSTEM_ERROR };

	public static Boolean isValid(String status) {
		if (status != null || VALID_STATUS.contains(status)) {
			return true;
		}
		return false;
	}
	
	public static Map<String, String> getAgreementStatusTypes() {
		return new Map<String, String> {
			'NEW_AGREEMENT' => NEW_AGREEMENT,
			'NEW_VERSION' => NEW_VERSION,
			'PENDING_REVIEW' => PENDING_REVIEW,
			'REVIEWED' => REVIEWED,
			'REVIEW_CANCELLED' => REVIEW_CANCELLED,
			'REVIEW_EXPIRED' => REVIEW_EXPIRED,
			'PENDING_APPROVAL' => PENDING_APPROVAL,
			'APPROVED' => APPROVED,
			'APPROVAL_CANCELLED' => APPROVAL_CANCELLED,
			'COMPLETED' => COMPLETED,
			'REJECTED' => REJECTED,
			'SIGNED' => SIGNED,
			'SIGNATURE_CANCELLED' => SIGNATURE_CANCELLED,
			'NO_STATUS' => NO_STATUS,
			'PENDING_SIGNATURE' => PENDING_SIGNATURE,
			'SYSTEM_ERROR' => SYSTEM_ERROR
		};
	}
}