public class GenMigrationBatch implements Database.Batchable<sObject>, Database.Stateful {

	// declaring as non-static, as these should hold value throughout batch execution
	private List<Exception> errors = new List<Exception>();
	private Map<String, Id> permissionMap = GenMigrationController.getAllPermissionSets();
	private String query;
	private String objectName;
	private static final String userStatusAsActive = 'Active';
	private static final String userStatusAsPending = 'Pending';
	private static final String TEMPLATE_OBJECT_NAME = 'dsgen__Template_Configuration__c';
	private static final String USER_OBJECT_NAME = 'User';

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
			query = 'SELECT Id, ' + GenMigrationApplication.namespacePrefix + 'Docusign_Admin__c, (SELECT PermissionSet.Name FROM PermissionSetAssignments WHERE PermissionSet.Name IN (\'DocuSign_Administrator\', \'DocuSign_User\', \'DocuSign_Generator\')) FROM User WHERE  Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name IN ( \'DocuSign_Gen_Template_Configuration\' , \'DocuSign_Gen_User\'))';
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
		List<GenTemplate__c> migrateGenTemplates = new List<GenTemplate__c> ();
		for (SObject genTemplConfig : templateConfigurations) {
			migrateGenTemplates.add (new GenTemplate__c (
				Name = String.valueof(genTemplConfig.get('Name')),
				ObjectMappings__c = String.valueof(genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Object_Mappings__c')),
				SourceObject__c = String.valueof(genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Starting_Object__c')),
				SignerMappings__c = String.valueof(genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Signer_Mappings__c')),
				UseAllTemplates__c = Boolean.valueof(genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Use_All_Templates__c')),
				UseCurrentRecord__c = Boolean.valueof(genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Use_Current_Record__c')),
				HasPreviewedDocuments__c = Boolean.valueof(genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Previewed_Documents__c')),
				StepsCompleted__c = (Decimal)genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Steps_Completed__c'),
				IsSample__c = Boolean.valueof(genTemplConfig.get(GenMigrationApplication.namespacePrefix + 'Sample__c'))
			));
		}
		if (Collection.isNotEmpty(migrateGenTemplates)) {
			insert migrateGenTemplates;
		}
	}

	private void updateGenPermissions(final List<User> users) {
		List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
		// Checking if users already have required DAL permission sets, if yes then excluding them from DML
		for (User user : users) {
			Boolean hasGeneratorPermission = false;
			Boolean hasAdminPermission = false;
			Boolean hasUserPermission = false;
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

			if (String.valueof(user.get(GenMigrationApplication.namespacePrefix + 'Docusign_Status__c')) == userStatusAsActive) {
				user.Status__c = userStatusAsPending;
			} else if (user.Status__c != userStatusAsActive) {
				user.Status__c = String.valueof(user.get(GenMigrationApplication.namespacePrefix + 'Docusign_Status__c'));
			}
			user.dfsle__Username__c = String.valueof(user.get(GenMigrationApplication.namespacePrefix + 'Docusign_User_Id__c'));
		}
		if (Collection.isNotEmpty(updateGenFields)) {
			update updateGenFields;
		}
	}

	// Updating Custom Setting record for tracking migration Status
	public void finish(final Database.BatchableContext bc) {
		if (errors.size() == 0) {
			if (objectName == USER_OBJECT_NAME) {
				GenMigrationController.updateGenCustomSettings();
				GenMigrationController.generateEmail(Label.MigrateUsersSubjectLine, Label.MigrateUsersEmailBody);
			}
			if (objectName == TEMPLATE_OBJECT_NAME) {
				GenMigrationController.updateGenCustomSettings();
				GenMigrationController.generateEmail(Label.MigrateTemplateSubjectLine, Label.MigrateTemplateEmailBody);
			}
		} else {
			GenMigrationSettings__c genSetting = GenMigrationSettings__c.getOrgDefaults();
			// if error,keeping Batch response in custom setting,trimming response to save in text field
			if (objectName == TEMPLATE_OBJECT_NAME) {
				genSetting.dfsle__TemplateMigrationBatchStatus__c = 'Failed ' + errors[0].getMessage().subString(0, errors[0].getMessage().length() > 200 ? 200 : errors[0].getMessage().length());
			} else if (objectName == USER_OBJECT_NAME) {
				genSetting.dfsle__UserMigrationBatchStatus__c = 'Failed ' + errors[0].getMessage().subString(0, errors[0].getMessage().length() > 200 ? 200 : errors[0].getMessage().length());
			}
			upsert genSetting;
		}
	}
}