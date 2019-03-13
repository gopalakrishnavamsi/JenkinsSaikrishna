/**
 * Representation of a DocuSign Agreement status.
 */
global class AgreementStatus {

    global static final String NEW_AGREEMENT = 'NEW';
    global static final String NEW_VERSION = 'NEW VERSION';

    global static final String PENDING_REVIEW = 'PENDING REVIEW';
    global static final String REVIEWED = 'REVIEWED';
    global static final String REVIEW_CANCELLED = 'REVIEW CANCELLED';
    global static final String REVIEWED_EXPIRED = 'REVIEWED EXPIRED ';

    global static final String PENDING_APPROVAL = 'PENDING APPROVAL';
    global static final String APPROVED = 'APPROVED';
    global static final String APPROVAL_CANCELLED = 'APPROVAL CANCELLED';
    global static final String COMPLETED = 'COMPLETED';

    global static final String REJECTED = 'REJECTED';
    global static final String SIGNED = 'SIGNED';
    global static final String SIGNATURE_CANCELLED = 'SIGNATURE CANCELLED';
    global static final String NO_STATUS = 'NO STATUS';
    global static final String PENDING_SIGNATURE = 'PENDING SIGNATURE';

}