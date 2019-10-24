public with sharing class CLMEOSViewController {
    public String hostingUrl {set; get;}
    public Boolean mappingExists {set; get;}
    public Boolean connectionError {set; get;}
    public String objectType {set; get;}
    public String errorMessage {set; get;}

    //Constructor called from VF page - CLMEOSView.page
    public CLMEOSViewController() {
        try {
            Permissions.verifyIsClmViewer();
            hostingUrl = '';
            Id sid = System.currentPageReference().getParameters().get('sid');
            if (sid != NULL) {
                DescribeSObjectResult objDetails = MetadataService.describeSObject(sid);
                if (objDetails != NULL) {
                    objectType = objDetails.getName();
                    EOSUrlResult eosRes = fetchUrl(sid);
                    if (eosRes.mappingExists) {
                        hostingUrl= eosRes.eosUrl;
                        mappingExists=true;
                        connectionError = false;
                    } else {
                        mappingExists = false;
                        connectionError = false;
                    }
                }
            }
        } catch (Exception ex) {
            LoggerService.getInstance().exception(ex, 'Failed to fetch clm Url');
            connectionError = true;
            mappingExists = false;
            errorMessage = ex.getMessage();
        }
    }

    @AuraEnabled
    public static EOSUrlResult getEOSUrl(Id recordId) {
        try {
            return fetchUrl(recordId);
        } catch (Exception ex) {
            LoggerService.getInstance().exception(ex, 'Failed to fetch clm Url');
            return new EOSUrlResult(true,true,null,ex.getMessage());
        }
    }

    public class EOSUrlResult {
        @AuraEnabled
        public final Boolean connectionError {private set; get;}
        @AuraEnabled
        public final Boolean mappingExists {private set; get;}
        @AuraEnabled
        public final String eosUrl {private set; get;}
        @AuraEnabled
        public final String errorMessage {private set; get;}

        public EOSUrlResult(Boolean connectionError, Boolean mappingExists, String eosUrl, String errorMessage) {
            this.connectionError = connectionError;
            this.mappingExists = mappingExists;
            this.eosUrl = eosUrl;
            this.errorMessage = errorMessage;
        }
    }

    private static EOSUrlResult fetchUrl(Id recordId) {
        Permissions.verifyIsClmViewer();
        EOSUrlResult eosResult;
        EOS_Type__c config = CLMService.getCurrentMappingConfig(recordId);
        if (config==null) {
            eosResult = new EOSUrlResult(false, false, '', null);
        } else {
            eosResult = new EOSUrlResult(false, true, CLMService.getHostingUrl(config, recordId).toExternalForm(), null);
        }
        return eosResult;
    }
}
