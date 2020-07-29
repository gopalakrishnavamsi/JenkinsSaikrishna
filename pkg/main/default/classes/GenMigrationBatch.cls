public class GenMigrationBatch implements Database.Batchable<sObject>, Database.Stateful {

	// declaring as non-static, as these should hold value throughout batch execution
	private List<Exception> errors = new List<Exception>();
	private Map<String, Id> permissionMap = GenMigrationController.getAllPermissionSets();
	private String query;
	private String objectName;
	private static final String TEMPLATE_OBJECT_NAME = 'dsgen__Template_Configuration__c';
	private static final String USER_OBJECT_NAME = 'User';
	private static final String ERROR_EMAIL_BODY = 'Could not migrate Template attachments to DocuSign Apps Launcher, due to following error:{0}';
	private static final String ERROR_EMAIL_SUBJECT = 'DocuSign Apps Launcher Template Migration Errors';


	// Identifying whether object is User or Template
	public GenMigrationBatch(final String sobjectName) {
		objectName = sobjectName;
		if (objectName == TEMPLATE_OBJECT_NAME) {
			query = 'SELECT Id,name,'
				+ GenMigrationApplication.namespacePrefix + 'Object_Mappings__c,'
				+ GenMigrationApplication.namespacePrefix + 'Previewed_Documents__c,'
				+ GenMigrationApplication.namespacePrefix + 'Sample__c,'
				+ GenMigrationApplication.namespacePrefix + 'Signer_Mappings__c,'
				+ GenMigrationApplication.namespacePrefix + 'Starting_Object__c,'
				+ GenMigrationApplication.namespacePrefix + 'Steps_Completed__c,'
				+ GenMigrationApplication.namespacePrefix + 'Use_All_Templates__c,'
				+ GenMigrationApplication.namespacePrefix + 'Use_Current_Record__c FROM ' + GenMigrationApplication.namespacePrefix + 'Template_Configuration__c';
		} else if (objectName == USER_OBJECT_NAME) {
			query = 'SELECT Id, IsActive, ' + GenMigrationApplication.namespacePrefix + 'Docusign_Admin__c, (SELECT PermissionSet.Name FROM PermissionSetAssignments WHERE PermissionSet.Name IN (\'DocuSign_Administrator\', \'DocuSign_User\', \'DocuSign_Generator\')) FROM User WHERE  Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name IN ( \'DocuSign_Gen_Template_Configuration\' , \'DocuSign_Gen_User\'))';
		}
	}

	public Database.QueryLocator start(final Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}

	public void execute(final Database.BatchableContext bc, final List<SObject> getQueryResult) {
		try {
			if (objectName == TEMPLATE_OBJECT_NAME) {
				List<SObject> templateConfigurtions = getQueryResult;
				if (Collection.isNotEmpty(templateConfigurtions)) migrateTemplates(templateConfigurtions);
			} else if (objectName == USER_OBJECT_NAME) {
				List<User> users = getQueryResult;
				if (Collection.isNotEmpty(users)) {
					updateGenPermissions(users);
				}
				// Updating user fields
				updateUserFieldsGentoDAL();
			}
		} catch (Exception ex) {
			errors.add(ex);
		}
	}

	private void migrateTemplates(final List<SObject> templateConfigurations) {
		Map<Id, GenTemplate__c> migrateGenTemplateResults = new Map<Id, GenTemplate__c> ();
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		for (sObject genTemplConfig : templateConfigurations) {
			migrateGenTemplateResults.put(genTemplConfig.id, new GenTemplate__c (
				Name = String.valueof(genTemplConfig.get('Name')),
				ObjectMappings__c = String.valueof(genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Object_Mappings__c')),
				SourceObject__c = String.valueof(genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Starting_Object__c')),
				SignerMappings__c = String.valueof(genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Signer_Mappings__c')),
				UseAllTemplates__c = Boolean.valueof(genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Use_All_Templates__c')),
				UseCurrentRecord__c = Boolean.valueof(genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Use_Current_Record__c')),
				HasPreviewedDocuments__c = Boolean.valueof(genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Previewed_Documents__c')),
				StepsCompleted__c = (Decimal)genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Steps_Completed__c'),
				TemplateType__c = Gen.TYPE_WORD,
				IsSample__c = Boolean.valueof(genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Sample__c'))));
		}
		if (Collection.isNotEmpty(migrateGenTemplateResults.values())) {
			insert migrateGenTemplateResults.values();
			migrateFiles(migrateGenTemplateResults);
		}
	}

	private void migrateFiles(final Map<Id, GenTemplate__c> tempConfGenTemplatesResult) {
		Map<Id, Id> contDocIdLinkedEntityId = new Map<Id, Id>();
		// If templates are more than 50,000, still only 50,000 template versions/files will be transfered
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>([SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN:tempConfGenTemplatesResult.keySet() LIMIT 50000]);
		if (contentDocumentLinks.isEmpty()) {
			return;
		}
		for (ContentDocumentLink contentDoc : contentDocumentLinks) {
			contDocIdLinkedEntityId.put(contentDoc.contentDocumentId, tempConfGenTemplatesResult.get(contentDoc.LinkedEntityId).ID);
		}
		insertContentVersions(contDocIdLinkedEntityId);
	}

	private void insertContentVersions(final Map<Id, Id> templateConfig) {
		List<ContentVersion> contentVersions = new List<ContentVersion>();
		List<Id> contentDocumentIds = new List<Id>(templateConfig.keySet());
		String contentVersionQuery = 'SELECT ' + GenMigrationApplication.namespacePrefix + 'Generated_File_Suffix__c,' + GenMigrationApplication.namespacePrefix + 'Generated_File_Name__c,' + GenMigrationApplication.namespacePrefix + 'Generated_File_Format__c,ContentDocumentId, Title, PathOnClient, VersionData From ContentVersion WHERE IsLatest= true ';
		for (ContentVersion contentVersion : Database.Query(contentVersionQuery + ' AND ContentDocumentId IN: contentDocumentIds')) {
			contentVersions.add(new ContentVersion(Title = contentVersion.Title,
				PathOnClient = contentVersion.PathOnClient,
				VersionData = contentVersion.VersionData,
				// Using ExternalDocumentInfo2 field to store OldTemp ContentDocumentId as unique identifier
				// ExternalDocumentInfo2 is OOTB field can be used to store externalIds
				ExternalDocumentInfo2 = contentVersion.ContentDocumentId,
				GeneratedFileFormat__c = String.valueof(contentVersion.get(GenMigrationApplication.namespacePrefix + 'Generated_File_Format__c')),
				GeneratedFileName__c = String.valueof(contentVersion.get(GenMigrationApplication.namespacePrefix + 'Generated_File_Name__c')),
				GeneratedFileSuffix__c = String.valueof(contentVersion.get(GenMigrationApplication.namespacePrefix + 'Generated_File_Suffix__c'))));
		}
		if (Collection.isNotEmpty(contentVersions)) {
			insert contentVersions;
			insertContentDocumentLinks(contentVersions, templateConfig);
		}
	}

	private void insertContentDocumentLinks(final List<ContentVersion> contentVersions, final Map<Id, Id> templateConfig) {
		List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
		try {
			for (ContentVersion objContent : [SELECT Id, ExternalDocumentInfo2,ContentDocumentId, VersionData FROM ContentVersion WHERE Id IN :contentVersions]) {
				contentDocumentLinks.add(new ContentDocumentLink(LinkedEntityId = templateConfig.get(objContent.ExternalDocumentInfo2),
					ContentDocumentId = objContent.ContentDocumentId,
					ShareType = 'V'));
			}
			if (Collection.isNotEmpty(contentDocumentLinks)) {
				insert contentDocumentLinks;
			}
		} catch (Exception ex) {
			GenMigrationController.generateEmail(ERROR_EMAIL_SUBJECT, String.format(ERROR_EMAIL_BODY, new List<String> { ex.getMessage() }));
		}
	}

	private void updateGenPermissions(final List<User> users) {
		List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
		// Checking if users already have required DAL permission sets, if yes then excluding them from DML
		for (User user : users) {
			Boolean hasGeneratorPermission = false;
			Boolean hasAdminPermission = false;
			Boolean hasUserPermission = false;
			// SF does not allow updating perm sets for inactive users
			if (user.IsActive) {
				for (PermissionSetAssignment assignment : user.PermissionSetAssignments) {
					if (assignment.PermissionSet.Name == GenMigrationController.DOCUSIGN_ADMINISTRATOR) hasAdminPermission = true;
					if (assignment.PermissionSet.Name == GenMigrationController.DOCUSIGN_GENERATOR) hasGeneratorPermission = true;
					if (assignment.PermissionSet.Name == GenMigrationController.DOCUSIGN_USER) hasUserPermission = true;
				}
				if (Boolean.valueof(user.get(GenMigrationApplication.namespacePrefix + 'Docusign_Admin__c')) && !hasAdminPermission) {
					permissionSetAssignments.add(new PermissionSetAssignment(PermissionSetId = permissionMap.get(GenMigrationController.DOCUSIGN_ADMINISTRATOR), AssigneeId = user.Id));
				} else if (!Boolean.valueof(user.get(GenMigrationApplication.namespacePrefix + 'Docusign_Admin__c')) && !hasGeneratorPermission) {
					permissionSetAssignments.add(new PermissionSetAssignment(PermissionSetId = permissionMap.get(GenMigrationController.DOCUSIGN_GENERATOR), AssigneeId = user.Id));
				}
				if (!hasUserPermission) {
					permissionSetAssignments.add(new PermissionSetAssignment(PermissionSetId = permissionMap.get(GenMigrationController.DOCUSIGN_USER), AssigneeId = user.Id));
				}
			}
		}
		if (Collection.isNotEmpty(permissionSetAssignments)) {
			insert permissionSetAssignments;
		}
	}

	private static void updateUserFieldsGentoDAL() {
		Permissions.verifyIsUpdateable(User.getSObjectType(), new List<String> {
			'CanManageAccount__c', 'Provisioned__c', 'Status__c', 'Username__c'
		});

		List<User> updateGenFields = GenMigrationApplication.getGenUsers();

		for (User user : updateGenFields) {
			user.CanManageAccount__c = Boolean.valueof(user.get(GenMigrationApplication.namespacePrefix + 'Docusign_Admin__c'));
			user.Provisioned__c = Date.valueof(user.get(GenMigrationApplication.namespacePrefix + 'DocuSign_Invitation_Date__c'));

			if (String.valueof(user.get(GenMigrationApplication.namespacePrefix + 'Docusign_Status__c')) == Account.USER_STATUS_ACTIVE) {
				user.Status__c = Account.USER_STATUS_PENDING;
			} else if (user.Status__c != Account.USER_STATUS_ACTIVE) {
				user.Status__c = String.valueof(user.get(GenMigrationApplication.namespacePrefix + 'Docusign_Status__c'));
			}
			user.Username__c = String.valueof(user.get(GenMigrationApplication.namespacePrefix + 'Docusign_User_Id__c'));
		}
		if (Collection.isNotEmpty(updateGenFields)) {
			update updateGenFields;
		}
	}

	// Updating Custom Setting record for tracking migration Status
	public void finish(final Database.BatchableContext bc) {
		if (errors.size() == 0) {
			if (objectName == USER_OBJECT_NAME) {
				GenMigrationController.updateUserGenCustomSettings();
				GenMigrationController.generateEmail(Label.MigrateUsersSubjectLine, Label.MigrateUsersEmailBody);
			}
			if (objectName == TEMPLATE_OBJECT_NAME) {
				Database.executeBatch(new WordTemplateUpdater());
				GenMigrationController.updateTemplateGenCustomSettings();
				GenMigrationController.generateEmail(Label.MigrateTemplateSubjectLine, Label.MigrateTemplateEmailBody);
			}
		} else {
			GenMigrationSettings__c genSetting = GenMigrationSettings__c.getOrgDefaults();
			// if error,keeping Batch response in custom setting,trimming response to save in text field
			if (objectName == TEMPLATE_OBJECT_NAME) {
				genSetting.TemplateMigrationBatchStatus__c = 'Failed ' + errors[0].getMessage().subString(0, errors[0].getMessage().length() > 200 ? 200 : errors[0].getMessage().length());
			} else if (objectName == USER_OBJECT_NAME) {
				genSetting.UserMigrationBatchStatus__c = 'Failed ' + errors[0].getMessage().subString(0, errors[0].getMessage().length() > 200 ? 200 : errors[0].getMessage().length());
			}
			update genSetting;
		}
	}
}