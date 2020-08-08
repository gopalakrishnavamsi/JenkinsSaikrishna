public with sharing class CLMService {

	private static string getValue(final String fieldName, final List<SObject> record) {
		String value = '';
		if (Collection.isNotEmpty(record)) {
			if (!fieldName.contains('.')) {
				value = String.valueOf(record.get(0).get(fieldName));
			} else {
				Map<String, Object> mapRecord = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(record.get(0)));
				List<String> fieldNameConfig = fieldName.split('\\.');
				for(Integer i =0; i < fieldNameConfig.size()-1; i++) {
					String referenceObjectName = fieldNameConfig.get(i);
					String referenceFieldName = fieldNameConfig.get(i+1);
					if (mapRecord.containsKey(referenceObjectName)) {
						Object o = mapRecord.get(referenceObjectName);
						Map<String, Object> mapInnerRecord = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(o));
						mapRecord.put(referenceFieldName, mapInnerRecord.get(referenceFieldName));
						value = String.valueOf(mapInnerRecord.get(referenceFieldName));
					}
				}
			}
		}
		return String.isBlank(value) ? '' : value;
	}

	private static List<SObject> query(final String field, final String objectName, final Id recordId) {
		List<SObject> result = new List<SObject>();
		DescribeSObjectResult objDetails = MetadataService.describeSObject(recordId);
		if (objDetails != null) {
			if (!field.contains('.')) {
				Permissions.verifyIsQueryable(objDetails.getSobjectType(), new List<String> {field});
			} else {
				String parentObjName = field.split('\\.')[0].trim();
				String parentfieldName = field.split('\\.')[1].replace('__r', '__c').trim();
				Permissions.verifyIsQueryable(Schema.getGlobalDescribe().get(parentObjName), new List<String> {parentfieldName});
			}
			result = new List<SObject>();
			if (String.isNotEmpty(field.trim()) && String.isNotEmpty(objectName) && String.isNotEmpty(recordId))
				result =  Database.query('select ' + String.escapeSingleQuotes(field.trim()) + ' from  ' + String.escapeSingleQuotes(objectName.trim()) + ' where id = :recordId');
		}
		return result;
	}

	public static EOS_Type__c getCurrentMappingConfig(final String recordId) {
		DescribeSObjectResult objectType = MetadataService.describeSObject(recordId);
		return EOS_Type__c.getInstance(objectType.getName());
	}

	public class SubstitutedParams {
		public final Id salesforceObjectId;
		public final String salesforceFolderName;
		public final String salesforceObjectType;
		public final String externalObjectStoragePath;
		SubstitutedParams(final String salesforceObjectId, final String salesforceFolderName, final String salesforceObjectType, final String externalObjectStoragePath) {
			this.salesforceObjectId = salesforceObjectId;
			this.salesforceFolderName = salesforceFolderName;
			this.salesforceObjectType = salesforceObjectType;
			this.externalObjectStoragePath = externalObjectStoragePath;
		}
	}

	public static SubstitutedParams substituteConfigValuesInTemplate(final EOS_Type__c config, final Id recordId) {
		SubstitutedParams subParams;
		String pathFormatConfig;
		List<String> folderConfig;
		List<String> variablesConfig = new List<String>();
		if (Application.namespace.equals('c')) {
			folderConfig = config.FolderName__c.split('\\.');
			variablesConfig = config.Variables__c.split(',');
			pathFormatConfig = config.PathFormat__c.trim();
		} else {
			folderConfig = String.valueOf(config.get(Application.namespacePrefix + 'FolderName__c')).split('\\.');
			if (!String.isEmpty(String.valueOf(config.get(Application.namespacePrefix + 'Variables__c')))) {
				variablesConfig = String.valueOf(config.get(Application.namespacePrefix + 'Variables__c')).split(',');
			}
			pathFormatConfig = String.valueOf(config.get(Application.namespacePrefix + 'PathFormat__c')).trim();
		}
		String parentObject = folderConfig.get(0).substringAfter('{!');
		String folderName = getFolderName(config.FolderName__c.trim(), parentObject.trim(), recordId);
		List<String> variables = new List<String>();
		for (String variable:variablesConfig) {
			List<String> variableConfigList = variable.split('\\.');
			String referenceObjectName = variableConfigList.get(0);
			String referenceFieldName = variableConfigList.get(1);
			if (referenceObjectName == parentObject) {
				variables.add(getValue(referenceFieldName, query(referenceFieldName,parentObject,recordId)));
			} else {
				variables.add(getValue(variable, query(variable,parentObject,recordId)));
			}
		}
		subParams = new SubstitutedParams(recordId, folderName, parentObject, String.format(pathFormatConfig,variables));
		return subParams;
	}

	private static String getFolderName(final String folderName, final String parentObject, final Id recordId) {
		String valueFolderName = folderName;
		String tempFolderName = folderName;
		while (tempFolderName.indexOf('{!') > -1) {
			String fn = tempFolderName.substringAfter('{!').substringBefore('}');
			String v = fn.startsWith(parentObject) ?
				getValue(fn.substringAfter('.'), query(fn.substringAfter('.'), parentObject, recordId)) :
				getValue(fn, query(fn, parentObject, recordId));
			valueFolderName = valueFolderName.replace('{!' + fn + '}', v);
			tempFolderName = tempFolderName.substringAfter('}');
		}
		return valueFolderName;
	}

	public static Url getHostingUrl(final EOS_Type__c config, final Id recordId) {
		CLMService.SubstitutedParams eosValues = substituteConfigValuesInTemplate(config, recordId);
		Url redirectionUrl = CLMAPI.getInstance().getClmUrl(eosValues);
		return redirectionUrl;
	}

	public static Url getDocumentGenerationLink() {
		Permissions.verifyIsClmUser();
		return CLMAPI.getInstance().getDocGenUrl();
	}	
}
