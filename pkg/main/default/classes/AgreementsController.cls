public with sharing class AgreementsController extends Controller {
	//FIXME : Add Test classes once the class body is locked down
	public AgreementsController() {
	}

	public AgreementsController(final ApexPages.StandardController c) {
	}

	@AuraEnabled(Cacheable = true)
	public static String getNameSpace() {
		try {
			Permissions.verifyIsDocuSignUser();
			return Application.namespace;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get namespace.');
		}
	}

	@AuraEnabled
	public static List<Agreement> getAgreements(final Id sourceObjectId) {
		try {
			return NegotiateService.getAgreements(sourceObjectId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get Agreements.');
		}

	}

	@AuraEnabled
	public static Agreement getAgreement(final String agreementId) {
		try {
			return NegotiateService.getAgreement(UUID.parse(agreementId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get Agreement.');
		}

	}

	@AuraEnabled
	public static List<Document> getLinkedDocuments(final Id sourceId) {
		try {
			Permissions.verifyIsDocuSignUser();
			return DocumentService.getLinkedDocuments(ContentVersion.getSObjectType(), new Set<Id> { sourceId }, false);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to get linked documents');
		}
	}

	@AuraEnabled
	public static NegotiateAPI.TaskStatus createAgreementInEOSFolder(final Id sfContentVersionId, final Id sourceObjectId, final String documentName) {
		try {
			return NegotiateService.createAgreementInEOSFolder(sfContentVersionId, sourceObjectId, documentName);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to create Agreement Folder');
		}
	}

	//Todo: Once access tokens are implemented return an instance of an object containing all needed params for generating Spring Widget Payload.
	@AuraEnabled
	public static String getDocumentURL(final String documentId) {
		try {
			return NegotiateService.getDocumentURL(UUID.parse(documentId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to generate document url');
		}
	}

	@AuraEnabled
	public static Boolean renameAgreement(final String documentId, final String documentName) {
		try {
			return NegotiateService.renameAgreement(UUID.parse(documentId), documentName);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to Rename Agreement');
		}
	}

	@AuraEnabled
	public static Boolean deleteAgreement(final String documentId) {
		try {
			return NegotiateService.deleteAgreement(UUID.parse(documentId));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to Delete Agreement');
		}
	}

	@AuraEnabled
	public static NegotiateService.LimitedAccessToken generateUploadToken(final Id objectId) {
		try {
			return NegotiateService.generateUploadToken(objectId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to generate upload access token.');
		}
	}

	@AuraEnabled
	public static NegotiateService.LimitedAccessToken generateDownloadToken(final UUID objectId) {
		try {
			return NegotiateService.generateDownloadToken(objectId);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to generate upload access token.');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static Recipient resolveRecipient(final Id sourceId) {
		try {
			Permissions.verifyIsDocuSignUser();
			Recipient result = null;
			if (String.isNotBlank(sourceId)) {
				List<Recipient> rs = RecipientService.getRecipients(sourceId.getSobjectType(), new Set<Id> { sourceId });
				if (Collection.isNotEmpty(rs)) {
					result = rs[0];
				}
			}
			return result;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to resolve recipients');
		}
	}

	@AuraEnabled
	public static String redirectToAgreementPreview(final Id sourceId, final String agreementId) {
		try {
			String result = NegotiateService.getAgreementPreviewLink(sourceId, agreementId);
			if (result == null) throw Controller.wrapException('Failed to redirect to Agreement Preview page: undefined parameter');
			return result;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to redirect to Agreement Preview');
		}
	}

	@AuraEnabled
	public static NegotiateAPI.TaskStatus sendForExternalReview(final String agreementName, final Id sourceId, final List<String> documentsIds, final String reviewersJson, final String subject, final String body, final Integer expiresInNumberOfDays) {
		try {
			if (String.isBlank(reviewersJson)) throw Controller.wrapException('Failed to send documents for External Review: Invalid Reviewers');
			List<UUID> documentIdList = new List<UUID>();
			List<Recipient> reviewers = (List<Recipient>) JSON.deserialize(reviewersJson, List<Recipient>.class);
			for (String documentId : documentsIds) {
				documentIdList.add(UUID.parse(documentId));
			}
			return NegotiateService.sendForExternalReview(agreementName, sourceId, documentIdList, reviewers, subject, body, expiresInNumberOfDays);
		} catch (Exception ex) {
			System.debug('ex: ' + ex.getMessage());
			throw Controller.wrapException(ex, 'Failed to send documents for External Review');
		}
	}

	@AuraEnabled
	public static NegotiateAPI.TaskStatus sendForInternalApproval(final String agreementName, final Id sourceId, final List<String> documentsIds, final String approversJson, final String subject, final String body) {
		try {
			if (String.isBlank(approversJson)) throw Controller.wrapException('Failed to send documents for Internal Approval: Invalid Approvers');			
			List<UUID> documentIdList = new List<UUID>();
			List<Recipient> approvers = (List<Recipient>) JSON.deserialize(approversJson, List<Recipient>.class);
			for (String documentId : documentsIds) {
				documentIdList.add(UUID.parse(documentId));
			}
			return NegotiateService.sendForInternalApproval(agreementName, sourceId, documentIdList, approvers, subject, body);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to send documents for Internal Approval');
		}
	}
}
