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
			return Application.lightningNamespace;
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
		if (sourceId == null || agreementId == null) return null;

		UUID agreementUId = UUID.parse(agreementId);
		PageReference agreementView = Page.AgreementPreview;
		agreementView.getParameters().put('sourceId', EncodingUtil.urlEncode(sourceId, StringUtils.ENCODING));
		agreementView.getParameters().put('agreementId', EncodingUtil.urlEncode(agreementUId.value, StringUtils.ENCODING));
		return agreementView.getUrl();
	}

	@AuraEnabled
	public static NegotiateAPI.TaskStatus sendForExternalReview(final List<String> documentsIds, final List<String> reviewerIds, final String subject, final String body, final Integer expiresInNumberOfDays) {
		try {
			List<UUID> documentIdList = new List<UUID>();
			for (String documentId : documentsIds) {
				documentIdList.add(UUID.parse(documentId));
			}
			return NegotiateService.sendForExternalReview(documentIdList, reviewerIds, subject, body, expiresInNumberOfDays);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to send documents for External Review');
		}
	}

	@AuraEnabled
	public static NegotiateAPI.TaskStatus sendForInternalApproval(final List<String> documentsIds, final List<String> reviewerIds, final String subject, final String body) {
		try {
			List<UUID> documentIdList = new List<UUID>();
			for (String documentId : documentsIds) {
				documentIdList.add(UUID.parse(documentId));
			}
			return NegotiateService.sendForInternalApproval(documentIdList, reviewerIds, subject, body);
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to send documents for Internal Approval');
		}
	}
}