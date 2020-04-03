public with sharing class GenMigrationController {

	// perm set names
	public static final String DOCUSIGN_ADMINISTRATOR = 'DocuSign_Administrator';
	private static final String DOCUSIGN_GEN_USER = 'DocuSign_Gen_User';
	private static final String DOCUSIGN_GEN_TEMPLATE_CONFIGURATION = 'DocuSign_Gen_Template_Configuration';
	public static final String DOCUSIGN_USER = 'DocuSign_User';
	public static final String DOCUSIGN_GENERATOR = 'DocuSign_Generator';
	private static final set<String> genPermissionSetNames = new set<String> { DOCUSIGN_ADMINISTRATOR, DOCUSIGN_GEN_USER, DOCUSIGN_GEN_TEMPLATE_CONFIGURATION, DOCUSIGN_USER, DOCUSIGN_GENERATOR };

	public class MigrateWrapper {
		@AuraEnabled
		public Boolean isGenPackageUser = true;

		@AuraEnabled
		public Integer onLoadUserCount { get; private set; }

		@AuraEnabled
		public Integer onLoadTemplateCount { get; private set; }

		@AuraEnabled
		public GenMigrationSettings__c getGenStatus { get; private set; }

		public MigrateWrapper(final Integer onLoadUserCount, final Integer onLoadTemplateCount, final GenMigrationSettings__c getGenStatus) {
			this.onLoadUserCount = onLoadUserCount;
			this.onLoadTemplateCount = onLoadTemplateCount;
			this.getGenStatus = getGenStatus;
		}

		public MigrateWrapper(final Boolean isGenPackageUser) {
			this.isGenPackageUser = isGenPackageUser;
		}
	}

	@AuraEnabled(Cacheable=true)
	public static MigrateWrapper isGenPackageInstalled() {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			return (GenMigrationApplication.verifyGenPackageInstalled()) ? new MigrateWrapper(GenMigrationApplication.getGenUsers().size(), Database.countQuery('SELECT count() FROM ' + GenMigrationApplication.namespacePrefix + 'Template_Configuration__c'), GenMigrationApplication.getGenSettings()) : new MigrateWrapper(GenMigrationApplication.verifyGenPackageInstalled());
		} catch (Exception ex) {
			throw Controller.wrapException(ex.getMessage());
		}
	}

	public static Map<String, Id> getAllPermissionSets() {
		Permissions.verifyIsQueryable(PermissionSet.getSObjectType(), new List<String> { 'Id', 'Name' });
		Map<String, Id> permissionSetNames = new Map<String, Id>();
		for (PermissionSet permissionSet : [SELECT Id,Name FROM PermissionSet WHERE Name IN:genPermissionSetNames]) {
			permissionSetNames.put(permissionSet.Name, permissionSet.Id);
		}
		return permissionSetNames;
	}

	@AuraEnabled
	public static Id initiateUserMigration() {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> {
				'Id',
				GenMigrationApplication.namespacePrefix + 'Docusign_Admin__c', 'email',
				GenMigrationApplication.namespacePrefix + 'DocuSign_Invitation_Date__c',
				GenMigrationApplication.namespacePrefix + 'Docusign_Status__c',
				GenMigrationApplication.namespacePrefix + 'Docusign_User_Id__c',
				'CanManageAccount__c',
				'Provisioned__c',
				'Status__c',
				'Username__c',
				'IsActive'
			});

			Permissions.verifyIsCreateable(PermissionSetAssignment.getSObjectType(), new List<String> { 'AssigneeId', 'PermissionSetId' });
			Id apexJobId = Database.executeBatch(new GenMigrationBatch('User'));
			//Passing batch Id in custom setting
			GenMigrationSettings__c genSetting = GenMigrationSettings__c.getOrgDefaults();
			genSetting.UserMigrationBatchId__c = apexJobId;
			upsert genSetting;
			return apexJobId;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to Assign permission sets to users');
		}
	}

	@AuraEnabled
	public static Id initiateTemplateMigration() {
		try {
			Permissions.verifyIsDocuSignAdministrator();
			Permissions.verifyIsCreateable(GenTemplate__c.getSObjectType(), new List<String> {
				'Name', 'SourceObject__c', 'ObjectMappings__c', 'SignerMappings__c', 'UseAllTemplates__c',
				'UseCurrentRecord__c', 'HasPreviewedDocuments__c', 'StepsCompleted__c', 'IsSample__c'
			});
			Permissions.verifyIsCreateable(ContentDocumentLink.getSObjectType(), new List<String> {
				'ContentDocumentId', 'LinkedEntityId', 'ShareType'
			});
			Permissions.verifyIsQueryable(ContentDocumentLink.getSObjectType(), new List<String> {
				'ContentDocumentId', 'LinkedEntityId'
			});
			Permissions.verifyIsCreateable(ContentVersion.getSObjectType(), new List<String> {
				'ExternalDocumentInfo2', 'GeneratedFileFormat__c', 'GeneratedFileName__c', 'GeneratedFileSuffix__c', 'ContentDocumentId', 'Title', 'VersionData', 'PathOnClient'
			});
			Permissions.verifyIsQueryable(ContentVersion.getSObjectType(), new List<String> {
				'ContentDocumentId', 'Title', 'PathOnClient', 'VersionData',
				GenMigrationApplication.namespacePrefix + 'Generated_File_Format__c',
				GenMigrationApplication.namespacePrefix + 'Generated_File_Name__c',
				GenMigrationApplication.namespacePrefix + 'Generated_File_Suffix__c'
			});
			Schema.DescribeSobjectResult[] getGenTemplateSobject = Schema.describeSObjects(new List<String> { GenMigrationApplication.namespacePrefix + 'template_configuration__C' });

			if (getGenTemplateSobject.get(0).getSobjectType() != null) {

				Permissions.verifyIsQueryable(getGenTemplateSobject.get(0).getSobjectType(), new List<String> {
					'Id',
					'Name',
					GenMigrationApplication.namespacePrefix + 'Object_Mappings__c',
					GenMigrationApplication.namespacePrefix + 'Previewed_Documents__c',
					GenMigrationApplication.namespacePrefix + 'Sample__c',
					GenMigrationApplication.namespacePrefix + 'Signer_Mappings__c',
					GenMigrationApplication.namespacePrefix + 'Starting_Object__c',
					GenMigrationApplication.namespacePrefix + 'Steps_Completed__c',
					GenMigrationApplication.namespacePrefix + 'Use_All_Templates__c',
					GenMigrationApplication.namespacePrefix + 'Use_Current_Record__c'
				});
			}

			Id apexJobId = Database.executeBatch(new GenMigrationBatch('dsgen__Template_Configuration__c'));
			// Saving Batch Job Id
			GenMigrationSettings__c genSetting = GenMigrationSettings__c.getOrgDefaults();
			genSetting.TemplateMigrationBatchId__c = apexJobId;
			upsert genSetting;
			return apexJobId;
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to Create Templates in DAL');
		}
	}

	// Calling this method FROM Batch class finish method to update custom setting for user migration
	public static void updateUserGenCustomSettings() {
		GenMigrationSettings__c genSetting = GenMigrationApplication.getGenSettings();
		if (genSetting.UserMigrationBatchId__c != null) {
			genSetting.GenUsersMigrated__c = true;
			genSetting.UserMigrationBatchStatus__c = '';
		}
		update genSetting;
	}

	// Calling this method FROM Batch class finish method to update custom setting for template migration
	public static void updateTemplateGenCustomSettings() {
		GenMigrationSettings__c genSetting = GenMigrationApplication.getGenSettings();
		if (genSetting.templateMigrationBatchId__c != null) {
			genSetting.GenTemplatesMigrated__c = true;
			genSetting.TemplateMigrationBatchStatus__c = '';
		}
		update genSetting;
	}

	// On Template or User migration sucess,sending Email to logged in user
	public static void generateEmail(final String getEmailSubject, final String getEmailBody) {
		try {
			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			email.setToAddresses(new List<String> { UserInfo.getUserEmail() });
			email.setSubject(getEmailSubject);
			email.setHTMLBody(getEmailBody);
			Messaging.SingleEmailMessage[] messages = new List <Messaging.SingleEmailMessage> { email };
			Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
		} catch (Exception ex) {
		}
	}
}
