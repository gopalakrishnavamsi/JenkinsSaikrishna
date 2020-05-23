public with sharing class CLMEOSViewController extends Controller {
    public String hostingUrl {set; get;}
    public Boolean mappingExists {set; get;}
    public Boolean connectionError {set; get;}
    public String objectType {set; get;}
    public String errorMessage {set; get;}

    public Entity sourceEntity { get; set; }

    public CLMEOSViewController() {
        Id sourceId = ApexPages.currentPage().getParameters().get('sid');
        if (sourceId != null && sourceEntity == null) {
            sourceEntity = Entity.resolve(sourceId);
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

    @AuraEnabled(Cacheable = true)
    public static String getNameSpace() {
        try {
            Permissions.verifyIsClmViewer();
            return Application.namespace;
        } catch (Exception ex) {
            throw Controller.wrapException(ex, 'Failed to get namespace.');
        }
    }
}
