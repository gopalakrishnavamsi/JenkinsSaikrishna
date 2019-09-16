public with sharing class CLMService{        
    
    private string getValue(String fieldName,List<SObject> record) {
        String value='';
        if (Collection.isNotEmpty(record)) {
            if(!fieldName.contains('.')){
                value=String.valueOf(record.get(0).get(fieldName));
            } else {
                Map<String,Object> mapRecord=(Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(record.get(0)));
                List<String> fieldNameConfig=fieldName.split('\\.'); 
                String referenceObjectName=fieldNameConfig.get(0);
                String referenceFieldName=fieldNameConfig.get(1);
                if (mapRecord.containsKey(referenceObjectName)) {
                    Object o=mapRecord.get(referenceObjectName);
                    Map<String,Object> mapInnerRecord =(Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(o));
                    value=String.valueOf(mapInnerRecord.get(referenceFieldName));
                }
            }			
        }
        return value;
    }
    
    private List<SObject> query(String field,String objectName,Id recordId) {
        List<SObject> result = new List<SObject>();
        DescribeSObjectResult objDetails = MetadataService.getObject(recordId);
        if (objDetails != null) {
            if (!field.contains('.')) {
            	Permissions.verifyIsQueryable(objDetails.getSobjectType(), new List<String>{field});    
            } else {
                string parentObjName=field.split('\\.')[0];
                string parentfieldName=field.split('\\.')[1].replace('__r', '__c');
                Permissions.verifyIsQueryable(Schema.getGlobalDescribe().get(parentObjName), new List<String>{parentfieldName});    
            }
            result = new List<SObject>();
            field=field.replace('__c', '__r');
            if (String.isNotEmpty(field) && String.isNotEmpty(objectName) && String.isNotEmpty(recordId))
                result =  Database.query('select '+ String.escapeSingleQuotes(field) + ' from  '+ String.escapeSingleQuotes(objectName) + ' where id = :recordId');             
        }
        return result;  
    }
    
    public static EOS_Type__c getCurrentMappingConfig(String recordId) {
        DescribeSObjectResult objectType=MetadataService.getObject(recordId);
        return EOS_Type__c.getInstance(objectType.getName());            	 
    }
    
    public class SubstitutedParams {
        public final Id salesforceObjectId;
        public final String salesforceFolderName;
        public final String salesforceObjectType;
        public final String externalObjectStoragePath;
        SubstitutedParams(String salesforceObjectId, String salesforceFolderName, String salesforceObjectType, String externalObjectStoragePath){
            this.salesforceObjectId = salesforceObjectId;
            this.salesforceFolderName = salesforceFolderName;
            this.salesforceObjectType = salesforceObjectType;
            this.externalObjectStoragePath = externalObjectStoragePath;
        }
    }
    
    public static SubstitutedParams substituteConfigValuesInTemplate(EOS_Type__c config, Id recordId) {
        SubstitutedParams subParams;
        String pathFormatConfig;
        List<String> folderConfig;
        List<String> variablesConfig = new List<String>();
        CLMService serviceInstance = new CLMService();
        if (Application.namespace.equals('c')) {            
            folderConfig=config.FolderName__c.split('\\.');
            variablesConfig = config.Variables__c.split(',');
            pathFormatConfig = config.PathFormat__c;
        } else {
            folderConfig=config.dfsle__FolderName__c.split('\\.');
            if (!String.isEmpty(config.dfsle__Variables__c)) {
                variablesConfig = config.dfsle__Variables__c.split(',');
            }        	
            pathFormatConfig = config.dfsle__PathFormat__c;
        }		
        String parentObject=folderConfig.get(0).substringAfter('{!');
        String folderApiName=folderConfig.get(1).substringBefore('}');
        String folderName=serviceInstance.getValue(folderApiName,serviceInstance.query(folderApiName,parentObject,recordId));
        List<String> variables = new List<String>();
        for (String variable:variablesConfig) {
            List<String> variableConfigList =variable.split('\\.'); 
            String referenceObjectName=variableConfigList.get(0);
            String referenceFieldName=variableConfigList.get(1);
            if (referenceObjectName==parentObject) {
                variables.add(serviceInstance.getValue(referenceFieldName,serviceInstance.query(referenceFieldName,parentObject,recordId)));
            } else {
                variables.add(serviceInstance.getValue(variable,serviceInstance.query(variable,parentObject,recordId)));
            }		   
        }
        subParams = new SubstitutedParams(recordId, folderName, parentObject, String.format(pathFormatConfig,variables));
        return subParams;
    }
    
    public static Url getHostingUrl(EOS_Type__c config, Id recordId) {	
        CLMService.SubstitutedParams eosValues = substituteConfigValuesInTemplate(config, recordId); 
        Url redirectionUrl = CLMAPI.getInstance().getClmUrl(eosValues);
        return redirectionUrl;
    }    
    
    public static Url getDocumentGenerationLink() {
		return CLMAPI.getInstance().getDocGenUrl();        
    }
    
    public static Url getWorkflowLink() {
		return CLMAPI.getInstance().getWorkflowUrl();        
    }
}