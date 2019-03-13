public with sharing class NegotiateAPI extends DocuSignAPI {
    // TODO: move common logic between GEN and Negotiate to parent class
    public static final String PATH_FOLDER = 'folders';
    public static final String PATH_DOCUMENTS = 'documents';
    public static final String PATH_AGREEMENT_IN_EOS_FOLDER = 'salesforcecontentdocumentimporttasks';

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

        EosInfo(String objectName, String objectId, String objectType) {
            this.name = objectName;
            this.objectId = objectId;
            this.objectType = objectType;
        }
    }

    // Create EOS folder in SpringCM Space
    public String createEOSFolder(String objectName, String objectId, String objectType) {

        RestAPI.Response response = post(
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
        return ((String) body.get('Href')).substringAfterLast('/');
    }

    @TestVisible
    private class APIAgreements {

        public List<Agreement> items;
        public String next;
    }


    @TestVisible
    private class APIFolder {
        public String href;

        APIFolder(String href) {
            this.href = href;
        }
    }

    //Create Agreement in EOS folder
    public String createAgreementInEOSFolder(String sfContentVersionId, String folderId, String docName) {

        RestAPI.Response response = post(
                getBaseUrl(),
                new List<String>{
                        PATH_AGREEMENT_IN_EOS_FOLDER
                },
                QueryString.empty,
                getDefaultHeaders(),
                JSON.serialize(new Map<String, Object>{
                        'SfContentVersionId' => sfContentVersionId,
                        'Folder' => new APIFolder(getBaseUrl() + '/' + PATH_FOLDER + '/' + folderId),
                        'Name' => docName
                }),
                RestAPI.defaultTimeout);
        if (response.hasError) {
            this.log.error('Failed to create Agreement in EOS folder: ' + response.error);
            throw new APIException(response.error);
        }

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.body);
        // taskId, we can use below taskId to check the status of the uploaded document
        return ((String) body.get('Href')).substringAfterLast('/');
    }

    //Get All Agreements from an EOS folder
    public List<Agreement> getAgreements(String folderId) {
        List<Agreement> agreements = new List<Agreement>();
        Map<String, String> queryStrings = new Map<String, String>();
        queryStrings.put('limit', '20');
        Long offset = -20;
        String next = '';

        while (next != null) {
            offset = +20;
            queryStrings.put('offset', String.valueOf(offset));

            RestAPI.Response response = get(
                    getBaseUrl(),
                    new List<String>{
                            PATH_FOLDER, folderId, PATH_DOCUMENTS
                    },
                    QueryString.empty,
                    getDefaultHeaders(),
                    RestAPI.defaultTimeout);
            if (response.hasError) {
                this.log.error('Failed to get Agreements from folderId - ' + folderId + ': ' + response.error);
                throw new APIException(response.error);
            }

            APIAgreements result = (APIAgreements) JSON.deserialize(response.body, APIAgreements.class);
            agreements.addAll(result.items);
            next = result.next;
        }

        return agreements;
    }

    // Rename Agreement

    public Boolean renameAgreement(String documentId, String docName) {

        RestAPI.Response response = put(
                getBaseUrl(),
                new List<String>{
                        PATH_DOCUMENTS, documentId
                },
                QueryString.empty,
                getDefaultHeaders(),
                JSON.serialize(new Map<String, Object>{
                        'Name' => docName
                }),
                RestAPI.defaultTimeout);
        if (response.hasError) {
            this.log.error('Failed to rename Agreement: ' + response.error);
            throw new APIException(response.error);
        }

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.body);
        return body.get('Name') == docName;
    }

}
