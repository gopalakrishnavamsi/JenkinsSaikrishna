public with sharing class NegotiateAPI extends DocuSignAPI {
    // TODO: move common logic between GEN and Negotiate to parent class
    public static final String PATH_FOLDER = 'folders';
    public static final String PATH_DOCUMENTS = 'documents';
    public static final String PATH_AGREEMENT_IN_EOS_FOLDER = 'salesforcecontentdocumentimporttasks';
    public static final String PATH_WORKFLOWS = 'workflows';

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

    @TestVisible
    private class APIExternalReview {
        
        public List<APIDocument> documents { get; private set; }
        public List<APIReviewer> reviewers { get; private set; }
        public APIEmail email { get; private set; }
        public Integer expiresInNumberOfDays { get; private set; }
        
        public APIExternalReview(final Integer expiresInNumberOfDays,final List<String> documentsIds, final List<String> reviewerIds, final String subject, final String message) {
            this.documents = NegotiateAPI.getAPIDocuments(documentsIds);
            this.reviewers = NegotiateAPI.getAPIReviewers(reviewerIds);
            this.email = new APIEmail(subject, message);
            this.expiresInNumberOfDays = expiresInNumberOfDays;
        }

        public String toXML() {
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartElement(null, 'Approval', null);
            //Documents
            w.writeCharacters(this.documentsToXML());
            //reviewers
            w.writeCharacters(this.reviewersToXML());
            //Email
            w.writeCharacters(this.email.toXML());   
            //ExpiresInNumberOfDays param
            w.writeStartElement(null, 'ExpiresInNumberOfDays', null); 
            w.writeCharacters(String.valueOf(this.expiresInNumberOfDays));
            w.writeEndElement();
            //CheckoutDocument param
            w.writeStartElement(null, 'CheckoutDocument', null); 
            w.writeCharacters('true');
            w.writeEndElement();
            //AssignTasksInOrder
            w.writeStartElement(null, 'AssignTasksInOrder', null); 
            w.writeCharacters('true');
            w.writeEndElement();
            //End       
            w.writeEndElement();
            String xml = w.getXmlString();
            w.close();
            return xml;         
        }

        private String documentsToXML() {
            XmlStreamWriter w = new XmlStreamWriter();
            //Header
            w.writeStartElement(null, 'Documents', null);
            for (APIDocument doc : this.documents) {
                w.writeCharacters(doc.toXML());
            }
            w.writeEndElement();
            String xml = w.getXmlString();
            w.close();
            return xml;                 
        }

        private String reviewersToXML() {
            XmlStreamWriter w = new XmlStreamWriter();
            //Header
            w.writeStartElement(null, 'Reviewers', null);
            for (APIReviewer entity : this.reviewers) {
                w.writeCharacters(entity.toXML());
            }
            w.writeEndElement();
            String xml = w.getXmlString();
            w.close();
            return xml;               
        }

    }

    @TestVisible
    private class APIApproval {
        
        public List<APIDocument> documents { get; private set; }
        public List<APIApprover> approvers { get; private set; }
        public APIEmail email { get; private set; }
        
        public APIApproval(final List<String> documentsIds, final List<String> approverIds, final String subject, final String message) {
            this.documents = NegotiateAPI.getAPIDocuments(documentsIds);
            this.approvers = NegotiateAPI.getAPIApprovers(approverIds);
            this.email = new APIEmail(subject, message);
        }

        public String toXML() {
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartElement(null, 'Approval', null);
            //Documents
            w.writeCharacters(this.documentsToXML());
            //Approvers
            w.writeCharacters(this.approversToXML());
            //Email
            w.writeCharacters(this.email.toXML());   
            //CheckoutDocument param
            w.writeStartElement(null, 'CheckoutDocument', null); 
            w.writeCharacters('true');
            w.writeEndElement();
            //AssignTasksInOrder
            w.writeStartElement(null, 'AssignTasksInOrder', null); 
            w.writeCharacters('true');
            w.writeEndElement();
            //End       
            w.writeEndElement();
            String xml = w.getXmlString();
            w.close();
            return xml;         
        }

        private String documentsToXML() {
            XmlStreamWriter w = new XmlStreamWriter();
            //Header
            w.writeStartElement(null, 'Documents', null);
            for (APIDocument doc : this.documents) {
                w.writeCharacters(doc.toXML());
            }
            w.writeEndElement();
            String xml = w.getXmlString();
            w.close();
            return xml;                 
        }

        private String approversToXML() {
            XmlStreamWriter w = new XmlStreamWriter();
            //Header
            w.writeStartElement(null, 'Approvers', null);
            for (APIApprover entity : this.approvers) {
                w.writeCharacters(entity.toXML());
            }
            w.writeEndElement();
            String xml = w.getXmlString();
            w.close();
            return xml;               
        }

    }

    //Todo: uid for now is an email address, this will most likely change in the future.    
    @TestVisible
    private class APIApprover {
        public String uid {get; private set;}

        public APIApprover(final String email) {
            this.uid = email;
        }

        public String toXML() {
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartElement(null, 'Approver', null);
            w.writeStartElement(null, 'Uid', null);
            w.writeCharacters(this.uid);
            w.writeEndElement();
            w.writeEndElement();
            String xml = w.getXmlString();
            w.close();
            return xml;
        }        
    }

    //Todo: uid for now is an email address, this will most likely change in the future.
    @TestVisible
    private class APIReviewer {
        public String uid {get; private set;}

        public APIReviewer(final String email) {
            this.uid = email;
        }

        public String toXML() {
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartElement(null, 'Reviewer', null);
            w.writeStartElement(null, 'Uid', null);
            w.writeCharacters(this.uid);
            w.writeEndElement();
            w.writeEndElement();
            String xml = w.getXmlString();
            w.close();
            return xml;
        }  
    }

    private class APIDocument  {

        public String id { get; private set; }

        public APIDocument(final String documentId) {
            this.id = documentId;
        }

        public String toXML() {
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartElement(null, 'Document', null);
            w.writeStartElement(null, 'Id', null);
            w.writeCharacters(this.id);
            w.writeEndElement();
            w.writeEndElement();
            String xml = w.getXmlString();
            w.close();
            return xml;
        }
    }

    private class APIEmail {

        public String subject { get; private set; }
        public String message { get; private set; }

        public APIEmail(final String subject, final String message) {
            this.subject = subject;
            this.message = message;
        }

        public String toXML() {
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartElement(null, 'Email', null);
            w.writeStartElement(null, 'Subject', null);
            w.writeCharacters(this.subject);
            w.writeEndElement();
            w.writeStartElement(null, 'Body', null);
            w.writeCharacters(this.message);
            w.writeEndElement();
            w.writeEndElement();
            String xml = w.getXmlString();
            w.close();
            return xml;
        }        
    }

    private static List<APIDocument> getAPIDocuments(final List<String> documentsIds) {
        List<APIDocument> documents = new List<APIDocument>();
        for(String docId : documentsIds) {
            documents.add(new APIDocument(docId));
        }
        return documents;
    }

    private static List<APIApprover> getAPIApprovers(final List<String> approverIds) {
        List<APIApprover> approvers = new List<APIApprover>();
        for (String approver : approverIds) {
            approvers.add(new APIApprover(approver));
        }
        return approvers;
    } 

    private static List<APIReviewer> getAPIReviewers(final List<String> reviewerIds) {
        List<APIReviewer> reviewers = new List<APIReviewer>();
        for (String reviewer : reviewerIds) {
            reviewers.add(new APIReviewer(reviewer));
        }
        return reviewers;
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
            this.log.error('Failed to rename Agreement: ' + documentId + ': ' + response.error);
            throw new APIException(response.error);
        }

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(response.body);
        return body.get('Name') == docName;
    }

    // Delete Agreement

    public Boolean deleteAgreement(String documentId) {

        RestAPI.Response response = del(
                getBaseUrl(),
                new List<String>{
                        PATH_DOCUMENTS
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

    //Send for Approval

    public Boolean sendForApproval(final String name, final List<String> documentsIds, final List<String> approverIds, final String subject, final String message) {

        RestAPI.Response response = post(
                getBaseUrl(),
                new List<String>{
                        PATH_WORKFLOWS    
                },
                QueryString.empty,
                getDefaultHeaders(),
                JSON.serialize(new Map<String, Object>{
                        'Name' => name,
                        'Params' => new APIApproval(documentsIds, approverIds, subject, message).toXML()
                }),
                RestAPI.defaultTimeout);
        if (response.hasError) {
            this.log.error('Failed to Send for Approval - ' + name + ': ' + response.error);
            throw new APIException(response.error);
        }

        return response.statusCode == 201;
    }

    //Send for External Review

    public Boolean sendForExternalReview(final String name, final List<String> documentsIds, final List<String> reviewerIds, final String subject, final String message, final Integer expiresInNumberOfDays) {

        RestAPI.Response response = post(
                getBaseUrl(),
                new List<String>{
                        PATH_WORKFLOWS    
                },
                QueryString.empty,
                getDefaultHeaders(),
                JSON.serialize(new Map<String, Object>{
                        'Name' => name,
                        'Params' => new APIExternalReview(expiresInNumberOfDays, documentsIds, reviewerIds, subject, message).toXML()
                }),
                RestAPI.defaultTimeout);
        if (response.hasError) {
            this.log.error('Failed to Send for External Review - ' + name + ': ' + response.error);
            throw new APIException(response.error);
        }

        return response.statusCode == 201;
    }    

}
