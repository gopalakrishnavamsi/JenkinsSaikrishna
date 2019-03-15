@IsTest
public with sharing class NegotiateAPIMock extends OAuthTokenMock {

    private final Boolean success;
    public static final UUID FOLDER_ID = UUID.parse('56322efe-e541-e911-9c1d-3ca82a1e3f41');
    public static final UUID DOCUMENT_ID = UUID.parse('382bd222-1536-e911-9c1d-3ca82a1e3f41');

    public NegotiateAPIMock(final Boolean success) {
        this.success = success;
    }

    public static NegotiateAPIMock success() {
        return (NegotiateAPIMock) TestUtils.setMock(new NegotiateAPIMock(true));
    }

    public static NegotiateAPIMock failure() {
        return (NegotiateAPIMock) TestUtils.setMock(new NegotiateAPIMock(false));
    }

    /* Supported routes:
    - POST /folders - Create EOS folder in SpringCM Space
    - POST /salesforcecontentdocumentimporttasks - Create Agreement in EOS folder
    - GET /folders/{folderId}/documents - Get All Agreements from an EOS folder
    - GET /documents/{documentId}/versions - Get All versions of an Agreement
    - PUT /documents/{documentId} - Rename Agreement
    - DELETE /documents/{documentId} - Delete Agreement
 */
    override public HttpResponse getResponse(final HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        String method = request.getMethod();
        String path = request.getEndpoint();

        if (success && method == 'POST' && path.contains(NegotiateAPI.PATH_FOLDER)) {
            response.setStatusCode(201);
            response.setStatus('CREATED');
            response.setBody('{"Href":"https://unit.test/folders/' + FOLDER_ID + '"}');
        } else if (success && method == 'POST' && path.contains(NegotiateAPI.PATH_AGREEMENT_IN_EOS_FOLDER)) {
            response.setStatusCode(201);
            response.setStatus('CREATED');
            response.setBody('{"Status": "Processing","Href": "https://apiuatna11.springcm.com/v201411/salesforcecontentdocumentimporttasks/4682d399-29fe-4085-9e48-126e4ffa0566"}');
        } else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_AGREEMENT_VERSIONS)) {
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setBody('{"Items":[{"Name":"newName.docx","CreatedDate":"2019-03-14T19:24:52.69Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-14T19:24:52.69Z","UpdatedBy":"pratik.hatkar@docusign.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":7,"Version":"3.0","PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=213e9c1a-8f46-e911-9c1d-3ca82a1e3f41","ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41","NativeFileSize":16808,"PdfFileSize":178269,"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41"},{"Name":"newName.docx","CreatedDate":"2019-03-14T19:24:04.233Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-14T19:24:04.233Z","UpdatedBy":"pratik.hatkar@docusign.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":7,"Version":"2.0","PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41","ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41","NativeFileSize":16808,"PdfFileSize":178269,"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41"},{"Name":"newName.docx","CreatedDate":"2019-03-08T21:35:08.97Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-14T19:14:39.68Z","UpdatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":5,"Version":"1.0","PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=996e80b6-8e46-e911-9c1d-3ca82a1e3f41","ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41","NativeFileSize":20557,"PdfFileSize":160453,"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41"}],"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/Versions","Offset":0,"Limit":20,"First":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/Versions","Last":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/Versions","Total":3}');
        } else if (success && method == 'GET') {
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setBody('{"Items":[{"Name":"docusignlogerror7-23-18-1.docx","CreatedDate":"2019-03-08T21:35:08.97Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-08T21:35:08.97Z","UpdatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41"},"HistoryItems":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/historyitems"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":5,"Lock":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/lock"},"PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=ea7ab407-ea41-e911-9c1d-3ca82a1e3f41","Versions":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/versions"},"ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41","NativeFileSize":20557,"PdfFileSize":160453,"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41"}],"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41/documents","Offset":0,"Limit":20,"First":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41/documents","Last":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41/documents","Total":1}');
        } else if (success && method == 'PUT') {
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setBody('{"Name":"docuTestRename.docx","CreatedDate":"2019-02-21T20:58:27.637Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-13T19:26:01.787Z","UpdatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/df5300b4-6135-e911-9c1d-3ca82a1e3f41"},"HistoryItems":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/historyitems"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":5,"Lock":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/lock"},"PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=382bd222-1536-e911-9c1d-3ca82a1e3f41","Versions":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/versions"},"ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41","NativeFileSize":16897,"PdfFileSize":160568,"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41"}');
        } else if (success && method == 'DELETE') {
            response.setStatusCode(200);
            response.setStatus('OK');
        } else {
            response.setStatusCode(400);
            response.setStatus('BAD_REQUEST');
            response.setBody('{"Error":{"HttpStatusCode":400,"UserMessage":"Test user message","DeveloperMessage":"Test developer message","ErrorCode":1234,"ReferenceId":"' + UUID.randomUUID() + '"}}');
        }

        return response;
    }

}
