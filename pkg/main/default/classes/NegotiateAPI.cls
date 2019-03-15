public with sharing class NegotiateAPI extends DocuSignAPI {
    // TODO: move common logic between GEN and Negotiate to parent class
    public static final String PATH_FOLDER = 'folders';
    public static final String PATH_DOCUMENTS = 'documents';
    public static final String PATH_AGREEMENT_IN_EOS_FOLDER = 'salesforcecontentdocumentimporttasks';
    public static final String PATH_AGREEMENT_VERSIONS = 'versions';

    private static NegotiateAPI self = null;

    private NegotiateAPI(final Url baseUrl) {
        super(new Url(baseUrl, '')); // TODO: use Negotiate baseURL, if any
    }

    public static NegotiateAPI getInstance() {
        if (self == null) {
            self = new NegotiateAPI(Credentials.getInstance().environment.scmApiBaseUrl); // TODO: as of now using Gen's
        }
        return self;
    }

    public class Error extends APIError {
        public UUID referenceId { get; private set; }

        public Error(
                final Integer code,
                final UUID referenceId,
                final String description) {

            super(code, description);

            this.referenceId = referenceId;
        }

        override public String toString() {
            return String.format(Label.ApiError_3, new List<String>{
                    String.valueOf(this.code),
                    this.description,
                    String.valueOf(this.referenceId)
            });
        }
    }

    @TestVisible
    override protected virtual APIError getError(final HttpResponse response) {
        APIError e = APIError.none;
        Integer statusCode = response.getStatusCode();
        if (statusCode >= 400) {
            String body = response.getBody();
            try {
                Map<String, Object> error = (Map<String, Object>) ((Map<String, Object>) JSON.deserializeUntyped(body))
                        .get('Error');
                e = new NegotiateAPI.Error(
                        error.containsKey('ErrorCode') ? (Integer) error.get('ErrorCode') : statusCode,
                        UUID.tryParse((String) error.get('ReferenceId')),
                        error.containsKey('UserMessage') ? (String) error.get('UserMessage') : response.getStatus());
                this.log.warn('Negotiate API error: ' + e);
            } catch (Exception ex) {
                this.log.exception(ex, 'Failed to parse Negotiate API error. Response body:\n' + body);
                e = new APIError(statusCode, response.getStatus());
            }
        }
        return e;
    }

    @TestVisible
    private class EosInfo {

        public String name ;
        public String objectId;
        public String objectType ;

        EosInfo(final String objectName, final String objectId, final String objectType) {
            this.name = objectName;
            this.objectId = objectId;
            this.objectType = objectType;
        }
    }

    // Create EOS folder in SpringCM Space
    public UUID createEOSFolder(final String objectName, final String objectId, final String objectType) {

        final RestAPI.Response response = post(
                getBaseUrl(),
                new List<String>{
                        PATH_FOLDER
                },
                QueryString.empty,
                getDefaultHeaders(),
                JSON.serialize(new Map<String, Object>{
                        'EosInfo' => new EosInfo(objectName, objectId, objectType)
                }),
                RestAPI.defaultTimeout);
        if (response.hasError) {
            this.log.error('Failed to create EOS folder: ' + response.error);
            throw new APIException(response.error);
        }

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.body);
        return UUID.parse(((String) body.get('Href')).substringAfterLast('/'));
    }

    @TestVisible
    private class APIAgreements {

        public List<APIAgreement> items;
        public String next;
    }

    @TestVisible
    private class APIAgreement {
        public String name;
        public Datetime createdDate;
        public String status;
        public String href;

        public Agreement convertAPIAgreement() {
            return new Agreement(
                    UUID.parse(this.href.substringAfterLast('/')),
                    this.name,
                    this.createdDate,
                    this.status);
        }
    }


    @TestVisible
    private class APIFolder {
        public String href;

        APIFolder(final String href) {
            this.href = href;
        }
    }

    //Create Agreement in EOS folder
    public UUID createAgreementInEOSFolder(final String sfContentVersionId, final UUID folderId, final String docName) {

        final RestAPI.Response response = post(
                getBaseUrl(),
                new List<String>{
                        PATH_AGREEMENT_IN_EOS_FOLDER
                },
                QueryString.empty,
                getDefaultHeaders(),
                JSON.serialize(new Map<String, Object>{
                        'SfContentVersionId' => sfContentVersionId,
                        'Folder' => new APIFolder(getBaseUrl() + '/' + PATH_FOLDER + '/' + folderId.toString()),
                        'Name' => docName
                }),
                RestAPI.defaultTimeout);
        if (response.hasError) {
            this.log.error('Failed to create Agreement in EOS folder: ' + response.error);
            throw new APIException(response.error);
        }

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.body);
        // taskId, we can use below taskId to check the status of the uploaded document
        return UUID.parse(((String) body.get('Href')).substringAfterLast('/'));
    }

    //Get All Agreements from an EOS folder
    public List<Agreement> getAgreements(final UUID folderId) {
        List<Agreement> agreements = new List<Agreement>();
        Map<String, String> queryStrings = new Map<String, String>();
        queryStrings.put('limit', '20');
        Long offset = -20;
        String next = '';

        while (next != null) {
            offset = +20;
            queryStrings.put('offset', String.valueOf(offset));

            final RestAPI.Response response = get(
                    getBaseUrl(),
                    new List<String>{
                            PATH_FOLDER, folderId.toString(), PATH_DOCUMENTS
                    },
                    QueryString.empty,
                    getDefaultHeaders(),
                    RestAPI.defaultTimeout);
            if (response.hasError) {
                this.log.error('Failed to get Agreements from folderId - ' + folderId + ': ' + response.error);
                throw new APIException(response.error);
            }

            APIAgreements result = (APIAgreements) JSON.deserialize(response.body, APIAgreements.class);
            for (APIAgreement a : result.items) {
                agreements.add(a.convertAPIAgreement());
            }
            next = result.next;
        }

        return agreements;
    }

    // Rename Agreement

    public Boolean renameAgreement(final UUID documentId, final String docName) {

        final RestAPI.Response response = put(
                getBaseUrl(),
                new List<String>{
                        PATH_DOCUMENTS, documentId.toString()
                },
                QueryString.empty,
                getDefaultHeaders(),
                JSON.serialize(new Map<String, Object>{
                        'Name' => docName
                }),
                RestAPI.defaultTimeout);
        if (response.hasError) {
            this.log.error('Failed to rename Agreement: ' + documentId + ': ' + response.error);
            throw new APIException(response.error);
        }

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.body);
        return body.get('Name') == docName;
    }

    // Delete Agreement

    public Boolean deleteAgreement(final UUID documentId) {

        final RestAPI.Response response = del(
                getBaseUrl(),
                new List<String>{
                        PATH_DOCUMENTS, documentId.toString()
                },
                QueryString.empty,
                getDefaultHeaders(),
                '',
                RestAPI.defaultTimeout);
        if (response.hasError) {
            this.log.error('Failed to delete Agreement - ' + documentId + ': ' + response.error);
            throw new APIException(response.error);
        }

        return response.statusCode == 200 ;
    }

    // Get all the versions of the Agreement
    public List<Agreement> getAgreementVersions(final UUID docId) {
        List<Agreement> agreements = new List<Agreement>();
        Map<String, String> queryStrings = new Map<String, String>();
        queryStrings.put('limit', '20');
        Long offset = -20;
        String next = '';

        while (next != null) {
            offset = +20;
            queryStrings.put('offset', String.valueOf(offset));

            final RestAPI.Response response = get(
                    getBaseUrl(),
                    new List<String>{
                            PATH_DOCUMENTS, docId.toString(), PATH_AGREEMENT_VERSIONS
                    },
                    QueryString.empty,
                    getDefaultHeaders(),
                    RestAPI.defaultTimeout);
            if (response.hasError) {
                this.log.error('Failed to get versions of Agreement - ' + docId + ': ' + response.error);
                throw new APIException(response.error);
            }

            APIAgreements result = (APIAgreements) JSON.deserialize(response.body, APIAgreements.class);
            for (APIAgreement a : result.items) {
                agreements.add(a.convertAPIAgreement());
            }
            next = result.next;
        }

        return agreements;
    }

}
