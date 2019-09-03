public with sharing class CLMMapObjectController {
	@AuraEnabled
    public static String getNamespace(){
		try {
			Permissions.verifyIsClmAdministrator();
			return Application.namespace;
		} catch (Exception e) {
			throw Controller.wrapException(e.getMessage());
		}
	}

	@AuraEnabled
	public static Boolean removeMappedObject(String name) {
		try {
			Permissions.verifyIsClmAdministrator();
			delete EOS_Type__c.getInstance(name);
			return true;
		} catch (Exception e) {
			throw Controller.wrapException(e.getMessage());
		}
	}
    
    @AuraEnabled
	public static Boolean setMappedObject(EOS_Type__c eosDetails) {
		try {
			Permissions.verifyIsClmAdministrator();
            Map<String,List<String>> pathDetails=parsePath(eosDetails.Path__c);
            if(pathDetails.containsKey('Variables') && pathDetails.containsKey('PathFormat')){
                eosDetails.Variables__c=String.join(pathDetails.get('Variables'),',');
                eosDetails.PathFormat__c=String.join(pathDetails.get('PathFormat'),'');
                eosDetails.FolderNameFormat__c='{'+pathDetails.get('Variables').size()+'}';
                String ObjectName=eosDetails.FolderName__c.split('\\.').get(0).substringAfter('{!');                
            }            
            upsert eosDetails;
			return true;
		} catch (Exception e) {
			throw Controller.wrapException(e.getMessage());
		}
    }
    
    private static Map<String,List<String>> parsePath(String path){
        Map<String,List<String>> result=new Map<String,List<String>>();
        List<String> variables=new List<String>();
        String formatted='';  
        Integer index=0;
        for(String folder:path.split('/')){
            String objName=folder.substringAfter('{!').substringBefore('}');
            if(String.isNotBlank(objName)){
                variables.add(objName);
                formatted += folder.substringBefore('{!')+'{'+index+'}'+folder.substringAfter('}')+'/';
                index++;
            }
            else{
                formatted += folder+'/';
            }
        }                
        result.put('Path',new List<String>{path});
        result.put('PathFormat',new List<String>{formatted});
        result.put('Variables',variables);
        
        return result;
    }

	@AuraEnabled
	public static Map<String, EOS_Type__c> getMappedObjectsList() {
		try {
			Permissions.verifyIsClmAdministrator();
			return EOS_Type__c.getAll();
		} catch (Exception e) {
			throw Controller.wrapException(e.getMessage());
		}
	}
    
    @AuraEnabled(Cacheable=true)
	public static List<MergeObject> getAllObjects() {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			return MetadataService.getObjects();
		} catch (Exception e) {
			throw Controller.wrapException(e.getMessage());
		}
	}

	@AuraEnabled(Cacheable=true)
	public static List<MergeField> getAllObjectFields(String apiName, Boolean isChild) {
		try {
			Permissions.verifyIsDocuSignAdministrator();
            SObjectType type = Schema.getGlobalDescribe().get(apiName);
            List<MergeField> result= new List<MergeField>();
            result.addAll(MetadataService.getFields(type, isChild));
            return result;
		} catch (Exception e) {
			throw Controller.wrapException(e.getMessage());
        }
    }

	@AuraEnabled
	public static Integer getRecordCount() {
		try {
			Permissions.verifyIsClmAdministrator();
			return EOS_Type__c.getAll().values().size();
		} catch (Exception e) {
			throw Controller.wrapException(e.getMessage());
		}
	}      
}