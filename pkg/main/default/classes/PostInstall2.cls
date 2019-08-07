/**
 * Initializes new custom settings in 2.0.
 */
public class PostInstall2 implements PostInstallScript {

	@TestVisible
	private static PostInstallResults initializeAccountSettings() {
		PostInstallResults result = new PostInstallResults();
		AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
		if (String.isBlank(settings.EncryptionKey__c)) {
			settings.EncryptionKey__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
			update settings;
			result.endStepSuccess(Label.InitializeAccountSettings);
		} else {
			result.skipStep(Label.InitializeAccountSettings, Label.AlreadyComplete);
		}
		return result;
	}

	@TestVisible
	private static PostInstallResults createDefaultCLMObjMappings(){
		PostInstallResults result = new PostInstallResults();
		EOS_Type__c eos = EOS_Type__c.getOrgDefaults();
		if(eos.Id == null){
			try{
				insertDefaultCLMObjMappings(eos, Label.Account);
				insertDefaultCLMObjMappings(eos, Label.Opportunity);
			}catch(Exception ex){
				result.endStepFailure(Label.CreateDefaultCLMObjMappings, ex);
			}
		} else{
			result.skipStep(Label.CreateDefaultCLMObjMappings, Label.AlreadyComplete);
		}
		return result;
	}

	private static void insertDefaultCLMObjMappings(EOS_Type__c eos, String obj){
				if(obj == Label.Account){
					eos.Folder_Name__c = Label.DefaultAccountFolderName;
					eos.Path__c = Label.DefaultAccountObjectMappingPath;
					eos.Name__c = Label.Account;
					eos.Folder_Name_Format__c	= Label.DefaultFolderNameFormat;
					eos.Variables__c = Label.DefaultAccountVariables;
					eos.Path_Format__c = Label.DefaultAccountPathFormat;			
					eos.Name = Label.Account;		
				} else if(obj == Label.Opportunity){
					eos.Folder_Name__c = Label.DefaultOpportunityFolderName;
					eos.Path__c = Label.DefaultOpportunityObjectMappingPath;
					eos.Name__c = Label.Opportunity;
					eos.Folder_Name_Format__c	= Label.DefaultFolderNameFormat;
					eos.Variables__c = Label.DefaultOpportunityVariables;
					eos.Path_Format__c = Label.DefaultOpportunityPathFormat;			
					eos.Name = Label.Opportunity;						
				}
				insert eos;
	}

	public Boolean shouldExecute(Id organizationId, Id installerId, Version previousVersion, Boolean isPush,
		Boolean isUpgrade) {

		return previousVersion != null
			&& previousVersion.major() < 2;
	}

	public PostInstallResults execute(Id organizationId, Id installerId, Version previousVersion, Boolean isPush,
		Boolean isUpgrade) {

		return new PostInstallResults().addResults(initializeAccountSettings());
	}
}